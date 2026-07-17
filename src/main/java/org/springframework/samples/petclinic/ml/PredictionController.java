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
		return this.predictionService.predictNoShow(petAge, petType, visitCount, previousNoShow);
	}

}
