문제해결

워커노드에서 join 시 apiserver의 CA token이 유효하지 않다는 오류가 발생한다.

error execution phase preflight: couldn't validate the identity of the API Server: invalid discovery token CA certificate hash: invalid hash "sha256:9a225953969f9164d08a9505c6f323e316c842656feeee9fca2715a6f8e7e9a", expected a 32 byte SHA-256 hash, found 31 bytes

마스터노드에서 토큰을 재생성하면 해결된다.
kubeadm token list
kubeadm delete token ....
kubeadm token create --print-join-command
