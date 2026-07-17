package org.springframework.samples.petclinic.ml;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sagemakerruntime.SageMakerRuntimeClient;
import software.amazon.awssdk.services.sagemakerruntime.model.InvokeEndpointRequest;
import software.amazon.awssdk.services.sagemakerruntime.model.InvokeEndpointResponse;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Service to invoke SageMaker endpoint for appointment no-show prediction.
 */
@Service
public class PredictionService {

	private static final Logger logger = LoggerFactory.getLogger(PredictionService.class);

	private final SageMakerRuntimeClient sageMakerClient;

	private final ObjectMapper objectMapper;

	@Value("${ml.sagemaker.endpoint-name:petclinic-predict-endpoint}")
	private String endpointName;

	@Value("${ml.sagemaker.enabled:false}")
	private boolean mlEnabled;

	public PredictionService(@Value("${ml.sagemaker.region:ap-south-1}") String region) {
		this.sageMakerClient = SageMakerRuntimeClient.builder().region(Region.of(region)).build();
		this.objectMapper = new ObjectMapper();
	}

	/**
	 * Predict whether a pet will miss its next appointment.
	 * @param petAge age of the pet in years
	 * @param petType type of pet (dog, cat, etc.)
	 * @param visitCount number of previous visits
	 * @param previousNoShow whether the pet had a previous no-show (0 or 1)
	 * @return prediction result with probability
	 */
	public PredictionResult predictNoShow(int petAge, String petType, int visitCount, int previousNoShow) {
		if (!mlEnabled) {
			logger.debug("ML predictions disabled, returning default");
			return PredictionResult.disabled();
		}

		try {
			String payload = String.format(
					"{\"pet_age\":%d,\"pet_type\":\"%s\",\"visit_count\":%d,\"previous_no_show\":%d}", petAge, petType,
					visitCount, previousNoShow);

			InvokeEndpointRequest request = InvokeEndpointRequest.builder()
				.endpointName(endpointName)
				.contentType("application/json")
				.body(SdkBytes.fromUtf8String(payload))
				.build();

			InvokeEndpointResponse response = sageMakerClient.invokeEndpoint(request);
			String responseBody = response.body().asUtf8String();

			JsonNode result = objectMapper.readTree(responseBody);
			JsonNode prediction = result.isArray() ? result.get(0) : result;

			return new PredictionResult(prediction.get("prediction").asInt(),
					prediction.get("probability_miss").asDouble(),
					prediction.get("probability_attend").asDouble(), prediction.get("label").asText());
		}
		catch (Exception e) {
			logger.error("Failed to invoke SageMaker endpoint: {}", e.getMessage());
			return PredictionResult.error(e.getMessage());
		}
	}

}
