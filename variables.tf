/*variable "key_name" {
  type        = string
  description = "The name for ssh key, used for aws_launch_configuration"
}

variable "cluster_name" {
  type        = string
  description = "The name of AWS ECS cluster"
}
*/

variable "key_name" {
  default = "swarm_key"
}

variable "cluster_name" {
  default = "web_cluster"
}

variable "aws_region" {
  default = "us-east-1"
}
