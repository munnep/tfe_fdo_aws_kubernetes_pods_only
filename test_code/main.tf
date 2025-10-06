terraform { 
  cloud { 
    hostname = "tfe71.aws.munnep.com" 
    organization = "test" 

    workspaces { 
      name = "test" 
    } 
  } 
}
# # This resource will destroy (potentially immediately) after null_resource.next
# data "external" "slow_delay" {
#   program = ["bash", "-c", <<EOT
#     sleep 30
#     echo '{ "result": "done" }'
# EOT
#   ]
# }

resource "null_resource" "test" {
}
