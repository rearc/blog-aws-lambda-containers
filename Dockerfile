FROM public.ecr.aws/lambda/nodejs:20 AS base

FROM base AS build

WORKDIR /app

COPY ./*.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci --progress=false

COPY ./src/ ./src/

RUN \
    npm run build

FROM base AS runtime

ARG PORT=8080

ENV PORT=${PORT} \
    NODE_ENV=production \
    AWS_LWA_ENABLE_COMPRESSION=true

COPY --from=build /app/package*.json ${LAMBDA_TASK_ROOT}

RUN --mount=type=cache,target=/root/.npm \
    npm ci --audit=false --progress=false

COPY --from=build /app/dist/ ${LAMBDA_TASK_ROOT}/dist/

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

EXPOSE ${PORT}

ENTRYPOINT ["node", "dist/main"]