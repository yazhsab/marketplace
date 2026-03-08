package media

// UploadResponse is the API representation of a successfully uploaded file.
type UploadResponse struct {
	Key string `json:"key"`
	URL string `json:"url"`
}
