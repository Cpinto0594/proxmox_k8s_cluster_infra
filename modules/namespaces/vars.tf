variable "namespaces" {
  description = "Namespaces to create, keyed by name, each with a map of labels."
  type        = map(map(string))
}
