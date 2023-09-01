fPATHS=
find $PATHS -type f -path '*/controlnet/*' -name '*.pth' -exec ln -s {} models/controlnet/ \;
find $PATHS -type f -path '*/checkpoints/*' \( -name '*.safetensors' -o -name '*.ckpt' \) -exec ln -s {} models/checkpoints/ \;
find $PATHS -type f \( -path '*/loras/*' -o -path '*/lycoris/*' \) \( -name '*.safetensors' -o -name '*.ckpt' \) -exec ln -s {} models/loras/ \;
find $PATHS -type f -path '*/embeddings/*' \( -name '*.safetensors' -o -name '*.ckpt' -o -name '*.pt' \) -exec ln -s {} models/embeddings/ \;