package org.springframework.samples.petclinic.ml;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for ML prediction endpoint. PetClinic calls this internally or
 * exposes it for demo purposes.
 */
@RestController
@RequestMapping("/api/predictions")
public class PredictionController {

	private final PredictionService predictionService;

	public PredictionController(PredictionService predictionService) {
		this.predictionService = predictionService;
	}

	/**
	 * Predict no-show probability for a pet's next appointment.
	 * @param petAge age of the pet
	 * @param petType type of pet (dog, cat)
	 * @param visitCount number of previous visits
	 * @param previousNoShow 1 if previously missed, 0 otherwise
	 * @return prediction result
	 */
	@GetMapping("/noshow")
	public PredictionResult predictNoShow(@RequestParam(defaultValue = "5") int petAge,
			@RequestParam(defaultValue = "dog") String petType,
			@RequestParam(defaultValue = "3") int visitCount,
			@RequestParam(defaultValue = "0") int previousNoShow) {
		return predictionService.predictNoShow(petAge, petType, visitCount, previousNoShow);
	}

}
