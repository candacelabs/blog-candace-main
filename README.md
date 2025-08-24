# blog

This tracks hugo-based sites, like the [blog](https://blog.candace.cloud) that are hosted on [candaceserver](https://candace.cloud). 

Fully containerized and plug-and-playable into any docker compose setup.

## Features

### Theme Features
- **Terminal Aesthetic**: Clean, monospace design inspired by command-line interfaces
- **Responsive Design**: Works on desktop and mobile devices
- **Dark Mode Ready**: Built with terminal-style dark colors
- **Social Links Integration**: Display GitHub, LinkedIn, Twitter, and email contacts
- **Recent Posts**: Automatic listing of your latest blog posts on the homepage
- **SEO Friendly**: Proper meta tags and semantic HTML structure

### Development Features
- **Live Reloading**: Instant preview of changes during development
- **Containerized Workflow**: No local Hugo installation required
- **Docker-based**: Consistent environment across all platforms
- **Hot Reload**: File changes automatically refresh the browser
- **Draft Support**: Preview draft posts during development

### Deployment Features
- **GitHub Pages Ready**: Automatic deployment via GitHub Actions
- **Static Site Generation**: Fast, secure static HTML output
- **Multiple Deployment Options**: Docker Compose, standalone Docker, or static files
- **Production Optimized**: Minified output and optimized assets
- **Custom Domain Support**: Easy integration with custom domains

### Technical Features
- **Hugo v0.148.0**: Latest Hugo version with extended features
- **No Build Dependencies**: Everything runs in containers
- **Version Controlled**: Theme and content separate from generated files
- **Modular Structure**: Easy to customize and extend
- **Modern Web Standards**: Clean HTML5 and CSS3

## Development & Testing

For development and testing, you can run everything in containers without needing Hugo installed locally:

### Development Server (Live Reloading)
```bash
# Build the development image
docker build -t blog-dev .

# Run development server with live reloading
docker run -it --rm \
  -p 1313:1313 \
  -v $(pwd)/bloghome/content:/srv/content \
  -v $(pwd)/bloghome/archetypes:/srv/archetypes \
  -v $(pwd)/bloghome/assets:/srv/assets \
  -v $(pwd)/bloghome/data:/srv/data \
  -v $(pwd)/bloghome/i18n:/srv/i18n \
  -v $(pwd)/bloghome/layouts:/srv/layouts \
  -v $(pwd)/bloghome/static:/srv/static \
  -v $(pwd)/bloghome/themes:/srv/themes \
  -v $(pwd)/bloghome/hugo.toml:/srv/hugo.toml \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo server --bind 0.0.0.0 -p 1313 --buildDrafts --buildFuture --disableFastRender
```

### Testing & Building
```bash
# Build static site for testing
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo --destination /srv/public

# Shell access for debugging
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev /bin/bash
```

### Quick Development Script
Create a `dev.sh` script for easier development:
```bash
#!/bin/bash
docker build -t blog-dev . && \
docker run -it --rm \
  -p 1313:1313 \
  -v $(pwd)/bloghome/content:/srv/content \
  -v $(pwd)/bloghome/archetypes:/srv/archetypes \
  -v $(pwd)/bloghome/assets:/srv/assets \
  -v $(pwd)/bloghome/data:/srv/data \
  -v $(pwd)/bloghome/i18n:/srv/i18n \
  -v $(pwd)/bloghome/layouts:/srv/layouts \
  -v $(pwd)/bloghome/static:/srv/static \
  -v $(pwd)/bloghome/themes:/srv/themes \
  -v $(pwd)/bloghome/hugo.toml:/srv/hugo.toml \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo server --bind 0.0.0.0 -p 1313 --buildDrafts --buildFuture --disableFastRender
```

Then run: `chmod +x dev.sh && ./dev.sh`

Visit http://localhost:1313 to see your site. Changes to files will automatically reload the browser.

### When You're Done Developing

After completing your development work:

```bash
# Build the final static site to verify everything works
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo --destination /srv/public

# Check for any Hugo build errors or warnings in the output above

# Verify the build succeeded by checking if files were generated
ls -la bloghome/public/

# Test the production build locally (optional)
docker run -it --rm -p 8080:8080 \
  -v $(pwd)/bloghome/public:/usr/share/nginx/html:ro \
  nginx:alpine

# Then visit http://localhost:8080 to test the static site
```

### Troubleshooting & Logs

```bash
# Check Hugo server logs while development server is running
# (logs appear directly in terminal when running ./dev.sh)

# Debug Hugo configuration issues
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo config

# Validate Hugo installation and version
docker run -it --rm blog-dev hugo version

# Check for theme or content issues with verbose output
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo --verbose --debug

# Shell access for detailed debugging
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev /bin/bash
# Then inside container: hugo --help, ls -la, cat hugo.toml, etc.
```

### Final Steps

```bash
# Clean up development image (optional)
docker rmi blog-dev

# Commit your changes
git add .
git commit -m "Update blog content and themes"
git push
```

The generated static files will be in `bloghome/public/` and ready for deployment.

## Production Deployment

### Docker Compose Integration (candace-server context)

For deployment in the candace-server environment:

1. Fork this repository or use it directly
2. `cd` to your main docker compose directory
3. Add as submodule:

```bash
git submodule add https://github.com/candacelabs/blog.git blog
```

4. Copy and configure the compose file:

```bash
cp blog/docker-compose.blog.example.yaml docker-compose.blog.yaml
```

5. Edit `docker-compose.blog.yaml`:
   - Change network names to match your environment
   - Update ports if 1313 is already in use
   - Verify volume paths match your blog structure

6. Add to your main `docker-compose.yml`:

```yaml
include:
  - docker-compose.blog.yaml
```

7. Deploy:

```bash
docker compose up blog -d
```

### Manual Deployment

For standalone deployment without docker-compose:

```bash
# Build production image
docker build -t blog-prod .

# Run production container
docker run -d \
  --name blog \
  -p 1313:1313 \
  -v $(pwd)/bloghome/content:/srv/content \
  -v $(pwd)/bloghome/archetypes:/srv/archetypes \
  -v $(pwd)/bloghome/assets:/srv/assets \
  -v $(pwd)/bloghome/data:/srv/data \
  -v $(pwd)/bloghome/i18n:/srv/i18n \
  -v $(pwd)/bloghome/layouts:/srv/layouts \
  -v $(pwd)/bloghome/static:/srv/static \
  -v $(pwd)/bloghome/themes:/srv/themes \
  -v $(pwd)/bloghome/hugo.toml:/srv/hugo.toml \
  --restart unless-stopped \
  blog-prod

# Check deployment status
docker logs blog

# Stop/start as needed
docker stop blog
docker start blog
```

### Static Site Deployment

To deploy as static files (nginx, Apache, etc.):

```bash
# Generate static files
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo --destination /srv/public

# Copy static files to web server
rsync -av bloghome/public/ user@server:/var/www/html/
# or
scp -r bloghome/public/* user@server:/var/www/html/
```

### GitHub Pages Deployment (Template Showcase)

To showcase your theme/template on GitHub Pages for sharing:

#### Option 1: GitHub Actions (Recommended)

1. Create `.github/workflows/hugo.yml`:

```yaml
name: Deploy Hugo site to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.148.0'
          extended: true

      - name: Build with Hugo
        working-directory: ./bloghome
        run: hugo --minify --baseURL "https://${{ github.repository_owner }}.github.io/${{ github.event.repository.name }}/"

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./bloghome/public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

2. In your GitHub repository settings:
   - Go to Settings → Pages
   - Set Source to "GitHub Actions"
   - Save

3. Update `bloghome/hugo.toml` to include:

```toml
# Add this line for GitHub Pages deployment
baseURL = "https://yourusername.github.io/blog"
```

#### Option 2: Manual Build & Deploy

```bash
# Generate static files with correct baseURL
docker run -it --rm \
  -v $(pwd)/bloghome:/srv \
  -v $(pwd)/themes:/srv/themes-standalone \
  blog-dev hugo --destination /srv/public --baseURL "https://yourusername.github.io/blog"

# Create gh-pages branch and deploy
git checkout --orphan gh-pages
git rm -rf .
cp -r bloghome/public/* .
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages
git checkout main
```

#### Sharing Your Template

After GitHub Pages is set up, create a demo repository:

1. **Fork/Template Setup**: Enable "Use this template" in your repository settings
2. **Demo Content**: Add sample posts and pages in `bloghome/content/`
3. **Documentation**: Include theme features, customization options, and installation instructions
4. **Screenshots**: Add images to showcase the theme design
5. **Live Demo Link**: Add your GitHub Pages URL to the repository description

Example repository description:
```
🎨 Hugo Blog Theme - Clean, minimal theme for technical blogs
📖 Live Demo: https://yourusername.github.io/blog
```

Your template will be live at `https://yourusername.github.io/blog` for others to preview before using it.
