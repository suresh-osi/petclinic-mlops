/*
 * Copyright 2012-2025 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.ml;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sagemakerruntime.SageMakerRuntimeClient;
import software.amazon.awssdk.services.sagemakerruntime.model.InvokeEndpointRequest;
import software.amazon.awssdk.services.sagemakerruntime.model.InvokeEndpointResponse;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

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

	public PredictionService(@Value("${ml.sagemaker.region:us-east-1}") String region) {
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
		if (!this.mlEnabled) {
			logger.debug("ML predictions disabled, returning default");
			return PredictionResult.disabled();
		}

		try {
			String payload = String.format(
					"{\"pet_age\":%d,\"pet_type\":\"%s\",\"visit_count\":%d,\"previous_no_show\":%d}", petAge, petType,
					visitCount, previousNoShow);

			InvokeEndpointRequest request = InvokeEndpointRequest.builder()
				.endpointName(this.endpointName)
				.contentType("application/json")
				.body(SdkBytes.fromUtf8String(payload))
				.build();

			InvokeEndpointResponse response = this.sageMakerClient.invokeEndpoint(request);
			String responseBody = response.body().asUtf8String();

			JsonNode result = this.objectMapper.readTree(responseBody);
			JsonNode prediction = result.isArray() ? result.get(0) : result;

			return new PredictionResult(prediction.get("prediction").asInt(),
					prediction.get("probability_miss").asDouble(),
					prediction.get("probability_attend").asDouble(), prediction.get("label").asText());
		}
		catch (Exception ex) {
			logger.error("Failed to invoke SageMaker endpoint: {}", ex.getMessage());
			return PredictionResult.error(ex.getMessage());
		}
	}

}
