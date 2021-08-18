FROM node:16-alpine3.14 AS base

RUN apk add --upgrade --no-cache tini --repository https://alpine.global.ssl.fastly.net/alpine/v3.10/community/

WORKDIR /app

COPY package.json .
COPY package-lock.json .

# ---- Dependencies ----
FROM base AS dependencies
# install node packages
RUN npm set progress=false && npm config set depth 0
RUN npm install --only=production
# copy production node_modules aside
RUN cp -R node_modules prod_node_modules
# install all node_modules including 'devDependencies'
RUN npm install

# ---- Test ----
FROM dependencies AS test
COPY ./ .
CMD ["npm", "test"]

# ---- Release ----
FROM base AS production
# copy production node_modules
COPY --from=dependencies /app/prod_node_modules ./node_modules
# copy app sources
COPY ./ .
RUN chown -R node:node /app
USER node

ENTRYPOINT node index.js