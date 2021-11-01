# Definition of Submission container

ARG ARCH=amd64
ARG MAJOR=daffy
ARG BASE_TAG=${MAJOR}-${ARCH}
ARG DOCKER_REGISTRY=docker.io

FROM ${DOCKER_REGISTRY}/duckietown/challenge-aido_lf-baseline-duckietown:${BASE_TAG} AS baseline

FROM ${DOCKER_REGISTRY}/duckietown/challenge-aido_lf-template-pytorch:${BASE_TAG} AS base

WORKDIR /code

COPY --from=baseline ${CATKIN_WS_DIR}/src/dt-car-interface ${CATKIN_WS_DIR}/src/dt-car-interface

COPY --from=baseline ${CATKIN_WS_DIR}/src/dt-core ${CATKIN_WS_DIR}/src/dt-core

COPY --from=baseline /data/config /data/config

COPY --from=baseline /code/submission_ws/src/agent /code/submission_ws/src/agent

# here, we install the requirements, some requirements come by default
# you can add more if you need to in requirements.txt

ARG PIP_INDEX_URL
ENV PIP_INDEX_URL=${PIP_INDEX_URL}

# since we are building FROM dt-core we need to install its dependencies
ARG DT_CORE_PATH=${CATKIN_WS_DIR}/src/dt-core
RUN dt-apt-install ${DT_CORE_PATH}/dependencies-apt.txt


RUN python3 -m pip install  pipdeptree
RUN python3 -m pip install -r ${DT_CORE_PATH}/dependencies-py3.txt

COPY requirements.* ./
RUN cat requirements.* > .requirements.txt
RUN python3 -m pip install -r .requirements.txt


RUN echo PYTHONPATH=$PYTHONPATH
RUN pipdeptree
RUN python3 -m pip list

COPY submission_ws/src submission_ws/src
COPY launchers/ launchers

ENV HOSTNAME=agent
ENV VEHICLE_NAME=agent
ENV ROS_MASTER_URI=http://localhost:11311

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    catkin build --workspace ${CATKIN_WS_DIR}

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    . ${CATKIN_WS_DIR}/devel/setup.bash  && \
    catkin build --workspace /code/submission_ws

ENV DISABLE_CONTRACTS=1
CMD ["bash", "launchers/run_and_start.sh"]
