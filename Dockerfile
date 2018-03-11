FROM perl:5.24.3

RUN apt-get update -yq\
        && apt-get install -yq\
            libssl1.0-dev \
            unzip \
        && apt-get clean\
        && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*


ENV APP_PATH="/app"

WORKDIR ${APP_PATH}
COPY cpanfile ${APP_PATH}


RUN cpanm -nq App::cpm
RUN cpm install -g Carton
RUN cpm install
RUN carton install

COPY app/ginpatu.pl /app/
CMD carton exec --  perl ./ginpatu.pl 
