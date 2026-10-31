# CadQuery for the mechanical models (enclosure/): STEP/STL export and headless renders.
FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libxrender1 \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir cadquery==2.8.0 pillow numpy
WORKDIR /work
