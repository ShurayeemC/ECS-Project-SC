# Setting the base image for the Dockerfile
FROM node:18-alpine AS builder

# Setting the working directory for the app
WORKDIR /app

# Copying the app dependencies | Copying app dependencies before source code is better practice as dependencies don't change as often as source code and is better for caching
COPY package.json yarn.lock ./

# Copying the rest of the source code
COPY . /app/ 

# Runs the commands to execute the build process for the image and yarn creates a directory called build which shows all the production files
RUN yarn install && yarn build

#---Runtime Stage---

# Setting the base image for the runtime stage
FROM node:18-alpine

# Setting the working directory for the app
WORKDIR /app

# Copying only the production build files from the builder stage
COPY --from=builder /app/build .

# Installing serve to host the static files
RUN yarn global add serve

RUN addgroup -S nonroot && adduser -S nonroot -G nonroot

RUN chown -R nonroot:nonroot /app

# Exposing port 3000 for the app
EXPOSE 3000

USER nonroot:nonroot

# Starting the app using serve in single page application mode
CMD ["serve", "-s", "."] 
