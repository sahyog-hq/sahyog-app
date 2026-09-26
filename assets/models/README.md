# TinyML anomaly detector

Drop a TFLite file here named `anomaly_detector.tflite`.

Expected tensors (float32):

- input: `[1, 50, 3]` — 50 accelerometer samples of `[x, y, z]` in g
- output: `[1, 1]` — anomaly probability in `[0, 1]`

If the file is missing, `AnomalyDetectionService` uses a local heuristic
scorer with the same sliding-window pipeline and SOS timer.
