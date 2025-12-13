# Packaged Lambda inside Dockerfile because Skicit library was too large for zip

###########################
# Image Building Commands
###########################
# docker buildx create --name lambda_builder --use
# docker buildx inspect --bootstrap
# docker buildx build \
#   --platform linux/amd64 \
#   -t inference:latest \
#   --load \
#   .
###########################

FROM public.ecr.aws/lambda/python:3.12

# Install Python dependencies
RUN pip install scikit-learn numpy scipy joblib --no-cache-dir

# Copy your Lambda code
COPY lambda/inference.py ${LAMBDA_TASK_ROOT}

CMD [ "inference.handler" ]