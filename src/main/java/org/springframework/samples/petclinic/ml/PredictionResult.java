package org.springframework.samples.petclinic.ml;

/**
 * Result from the appointment no-show prediction model.
 */
public class PredictionResult {

	private final int prediction;

	private final double probabilityMiss;

	private final double probabilityAttend;

	private final String label;

	private final boolean available;

	private final String errorMessage;

	public PredictionResult(int prediction, double probabilityMiss, double probabilityAttend, String label) {
		this.prediction = prediction;
		this.probabilityMiss = probabilityMiss;
		this.probabilityAttend = probabilityAttend;
		this.label = label;
		this.available = true;
		this.errorMessage = null;
	}

	private PredictionResult(boolean available, String errorMessage) {
		this.prediction = -1;
		this.probabilityMiss = 0.0;
		this.probabilityAttend = 0.0;
		this.label = "Unavailable";
		this.available = available;
		this.errorMessage = errorMessage;
	}

	public static PredictionResult disabled() {
		return new PredictionResult(false, "ML predictions are disabled");
	}

	public static PredictionResult error(String message) {
		return new PredictionResult(false, message);
	}

	public int getPrediction() {
		return prediction;
	}

	public double getProbabilityMiss() {
		return probabilityMiss;
	}

	public double getProbabilityAttend() {
		return probabilityAttend;
	}

	public String getLabel() {
		return label;
	}

	public boolean isAvailable() {
		return available;
	}

	public String getErrorMessage() {
		return errorMessage;
	}

	public String getProbabilityMissPercent() {
		return String.format("%.0f%%", probabilityMiss * 100);
	}

}
