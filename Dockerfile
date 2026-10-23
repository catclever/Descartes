FROM ruby:3.3-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock descartes.gemspec ./
COPY lib/descartes/version.rb ./lib/descartes/version.rb

# Install dependencies (llm_json and ruby_llm will be fetched from GitHub if not local)
RUN bundle install

COPY . .

EXPOSE 8089

HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8089/healthz || exit 1

CMD ["bundle", "exec", "bin/descartes-hub", "--port", "8089", "--host", "0.0.0.0"]
