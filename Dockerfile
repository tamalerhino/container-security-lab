# Step 1: Use a base Node.js image
FROM node:14

# Step 2: Create and set the working directory
WORKDIR /usr/src/app

# Step 3: Copy the application code
COPY app/ .

# Step 4: Install dependencies (none in this case, but npm install can be added)
# RUN npm install

# Step 5: Expose the application port
EXPOSE 3000

# Step 6: Start the application
CMD ["node", "index.js"]

