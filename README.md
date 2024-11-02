# Container Security Lab

This repository demonstrates a secure container pipeline using GitHub Actions. The goal is to showcase security best practices at each stage of the software supply chain, focusing on containerization.

## Key Concepts

- **Software Supply Chain Security**: Protecting the software delivery process from development to deployment.
- **Containerization**: Building, scanning, signing, and validating containers to ensure the integrity of your application.

## Pipeline Overview

1. **CodeQL Static Analysis (SAST)**: Analyze the source code for vulnerabilities.
2. **Build and Push Docker Image**: Build the container and push it to DockerHub.
3. **Trivy Scan (SCA)**: Scan the Docker image for known vulnerabilities in dependencies.
4. **Sign Docker Image with Cosign**: Sign the container to verify integrity.
5. **Validate Image Signature**: Ensure the image hasn't been tampered with.
6. **Generate SBOM**: Create a Software Bill of Materials to track dependencies.

## Tools Used

- **[CodeQL](https://github.com/github/codeql-action)**: Static Application Security Testing (SAST).
- **[Trivy](https://github.com/aquasecurity/trivy-action)**: Vulnerability scanner for containers.
- **[Cosign](https://github.com/sigstore/cosign)**: Tool for signing and verifying container images.
- **[SBOM](https://github.com/anchore/sbom-action)**: Generate and manage SBOMs.

## Workflow Configuration

Here's a quick breakdown of the steps in the `.github/workflows/ci.yml` file:

1. **CodeQL Analysis**:
   ```yaml
   codeql:
     name: Run CodeQL SAST
     runs-on: ubuntu-latest
     permissions:
       security-events: write
     steps:
       - name: Checkout Code
         uses: actions/checkout@v4
       - name: Initialize CodeQL
         uses: github/codeql-action/init@v3
         with:
           languages: javascript-typescript
       - name: Autobuild
         uses: github/codeql-action/autobuild@v3
       - name: Perform CodeQL Analysis
         uses: github/codeql-action/analyze@v3
         with:
           category: "/language:javascript-typescript"
   ```

2. **Build and Push Docker Image**:
   ```yaml
   build-push:
     name: Build and Push Container Image
     runs-on: ubuntu-latest
     needs: codeql
     steps:
       - name: Set up Docker Buildx
         uses: docker/setup-buildx-action@v3
       - name: Login to Dockerhub
         uses: docker/login-action@v3
         with:
           username: ${{ secrets.DOCKER_USERNAME }}
           password: ${{ secrets.DOCKER_PASSWORD }}
       - name: Build and Publish Container Image
         uses: docker/build-push-action@v3
         with:
           push: true
           tags: |
             ${{ secrets.DOCKER_USERNAME }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
   ```

3. **Trivy Vulnerability Scan**:
   ```yaml
   trivy:
     name: Run Trivy Scan
     runs-on: ubuntu-latest
     needs: build-push
     steps:
       - name: Install Trivy
         uses: aquasecurity/trivy-action@0.28.0
         with:
           image-ref: '${{ secrets.DOCKER_USERNAME }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}'
           format: 'table'
           exit-code: '1'
           ignore-unfixed: true
           vuln-type: 'os,library'
           severity: 'CRITICAL,HIGH'
   ```

4. **Sign Image with Cosign**:
   ```yaml
   sign:
     name: Sign Container Image with Cosign
     runs-on: ubuntu-latest
     needs: trivy
     steps:
       - name: Login to Dockerhub
         uses: docker/login-action@v3
         with:
           username: ${{ secrets.DOCKER_USERNAME }}
           password: ${{ secrets.DOCKER_PASSWORD }}
       - name: Install Cosign
         uses: sigstore/cosign-installer@v3.7.0
       - name: Sign Container Image
         run: |
             cosign sign --yes --key env://COSIGN_KEY ${{ secrets.DOCKER_USERNAME }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
         env:
           COSIGN_KEY: ${{secrets.COSIGN_PRIVATE_KEY}}
           COSIGN_PASSWORD: ${{secrets.COSIGN_PASSWORD}}
   ```

5. **Validate Image Signature and Generate SBOM**:
   ```yaml
   validate-container:
     name: Validate Container Image
     runs-on: ubuntu-latest
     needs: sign
     steps:
       - name: Install Cosign
         uses: sigstore/cosign-installer@v3.7.0
       - name: Write public key to disk
         run: 'echo "$KEY" > cosign.key'
         env:
           KEY: ${{ secrets.COSIGN_PUBLIC_KEY }}
       - name: Check images
         run: |
           cosign verify --key cosign.key ${{ secrets.DOCKER_USERNAME }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
       - uses: anchore/sbom-action@v0
         with:
           image: ${{ secrets.DOCKER_USERNAME }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
           format: cyclonedx
           upload-artifact-retention: 30
   ```

## How to Use

1. Clone this repository:
   ```bash
   git clone https://github.com/your-repo/container-security-lab.git
   ```

2. Set up GitHub Secrets for:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
   - `COSIGN_KEY`
   - `COSIGN_PUBLIC_KEY`
   - `COSIGN_PRIVATE_KEY`
   - `COSIGN_PASSWORD`

3. Push code to trigger the GitHub Actions pipeline.

## Conclusion

This pipeline integrates key security practices into the containerization process, helping you secure your software supply chain by scanning, signing, and verifying containers. Feel free to modify and extend the workflow based on your project’s needs.
