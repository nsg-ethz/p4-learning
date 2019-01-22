
* **Generate Digest:** Generate a packet digest and send it to the receiver.

* **Resubmit:** Resubmit the original packet to the parser with metadata. It can be applied only at the ingress.  

* **Recirculate:** Resubmit the packet after all egress modifications. It can be applied at egress only.

* **Clone:** Generate a packet digest and send it to the receiver.

  + ingress_to_ingress: Send a copy of the original packet to the parser. Alias: clone_i2i
  + egress_to_ingress: Send a copy of the egress packet to the parser. Alias: clone_e2i
  + ingress_to_egress: Send a copy of the original packet to the Buffer Mechanism. Alias: clone_i2e
  + egress_to_egress: Send a copy of the egress packet to the Buffer Mechanism. Alias: clone_e2e.
  
  

