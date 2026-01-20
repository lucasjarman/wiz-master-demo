terraform {
  required_version = ">= 1.3.0"
  required_providers {
    wiz = {
      version = ">= 1.21"
      source  = "tf.app.wiz.io/wizsec/wiz"
    }
  }
}
