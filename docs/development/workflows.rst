Development Workflows
=====================

This section covers comprehensive development workflows for data science, enterprise development, and system administration using the Siege Analytics ZSH Configuration System.

Data Science Workflows
----------------------

Complete Data Science Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Environment Setup
^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Setup Python environment
   setup_pyenv
   pyenv install 3.11.7
   pyenv virtualenv 3.11.7 data_science
   pyenv activate data_science

   # 2. Install data science packages
   pip install pandas numpy matplotlib seaborn jupyter scikit-learn

   # 3. Load big data stack
   load_big_data

   # 4. Start Spark-enabled Jupyter
   jupyter_spark 8889

Project Structure
^^^^^^^^^^^^^^^^^

.. code-block:: text

   data_science_project/
   ├── data/                    # Raw data files
   ├── notebooks/               # Jupyter notebooks
   ├── src/                     # Source code
   ├── models/                  # Trained models
   ├── results/                 # Analysis results
   ├── requirements.txt         # Python dependencies
   └── README.md               # Project documentation

Geospatial Analytics Workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Setup Geospatial Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Create geospatial environment
   pyenv virtualenv 3.11.7 geo_analysis
   pyenv activate geo_analysis

   # 2. Install geospatial packages
   pip install geopandas shapely folium contextily
   pip install apache-sedona-python  # For Spark geospatial

   # 3. Load Spark with geospatial support
   load_big_data
   jupyter_spark 8889

   # 4. In Jupyter, geospatial libraries are available
   # - Spark with Sedona
   # - GeoPandas for local processing
   # - Folium for mapping

Large-Scale Data Processing
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Configure Spark for large datasets
   export SPARK_DRIVER_MEMORY="8g"
   export SPARK_EXECUTOR_MEMORY="4g"

   # 2. Start Spark cluster
   load_big_data

   # 3. Process large datasets
   spark-submit --master local[*] \
     --conf spark.sql.adaptive.enabled=true \
     large_data_processing.py

Machine Learning Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~

Model Development
^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Setup ML environment
   pyenv virtualenv 3.11.7 ml_pipeline
   pyenv activate ml_pipeline

   # 2. Install ML packages
   pip install scikit-learn xgboost lightgbm
   pip install mlflow  # For experiment tracking

   # 3. Start Jupyter for model development
   jupyter_spark 8889

Model Training and Evaluation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Train models with Spark MLlib
   spark-submit --class MLPipeline \
     --master local[*] \
     ml_pipeline.py

   # 2. Evaluate models
   python evaluate_models.py

   # 3. Deploy models
   mlflow models serve -m models:/production_model/1

Enterprise Development Workflows
--------------------------------

Modern Web Development
~~~~~~~~~~~~~~~~~~~~~~

API Development with FastAPI
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Create new project
   mkdir my_api && cd my_api
   uv_init_project 3.12

   # 2. Add dependencies
   uv add fastapi uvicorn
   uv add --dev pytest black ruff

   # 3. Create API structure
   mkdir app
   touch app/__init__.py
   touch app/main.py

   # 4. Run development server
   uv run uvicorn app.main:app --reload

Microservices Architecture
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Create service directory
   mkdir microservices && cd microservices

   # 2. Create individual services
   mkdir user-service auth-service data-service

   # 3. Setup each service
   cd user-service
   uv_init_project 3.12
   uv add fastapi uvicorn sqlalchemy

   # 4. Run all services
   uv run uvicorn app.main:app --port 8001 &
   uv run uvicorn app.main:app --port 8002 &
   uv run uvicorn app.main:app --port 8003 &

Database Integration
~~~~~~~~~~~~~~~~~~~~

PostgreSQL Integration
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Install PostgreSQL tools
   brew install postgresql  # macOS
   # or
   sudo apt install postgresql postgresql-contrib  # Ubuntu

   # 2. Setup database
   createdb myapp_db

   # 3. Install Python database packages
   uv add sqlalchemy psycopg2-binary alembic

   # 4. Run migrations
   uv run alembic upgrade head

Redis Integration
^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Install Redis
   brew install redis  # macOS
   # or
   sudo apt install redis-server  # Ubuntu

   # 2. Start Redis
   redis-server

   # 3. Install Python Redis client
   uv add redis

   # 4. Use Redis in application
   uv run python -c "import redis; r = redis.Redis(); print(r.ping())"

Docker Development
------------------

Containerized Development
~~~~~~~~~~~~~~~~~~~~~~~~~

Dockerfile for Python Applications
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: dockerfile

   FROM python:3.12-slim

   # Install system dependencies
   RUN apt-get update && apt-get install -y \
       git curl wget build-essential \
       && rm -rf /var/lib/apt/lists/*

   # Install SDKMAN
   RUN curl -s "https://get.sdkman.io" | bash
   RUN bash -c "source ~/.sdkman/bin/sdkman-init.sh && \
       sdk install java 17.0.9-tem && \
       sdk install spark 3.5.3"

   # Set working directory
   WORKDIR /app

   # Copy requirements and install
   COPY requirements.txt .
   RUN pip install -r requirements.txt

   # Copy application code
   COPY . .

   # Expose port
   EXPOSE 8000

   # Run application
   CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

Docker Compose for Full Stack
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: yaml

   version: '3.8'
   services:
     app:
       build: .
       ports:
         - "8000:8000"
       environment:
         - DATABASE_URL=postgresql://user:pass@db:5432/myapp
         - REDIS_URL=redis://redis:6379
       depends_on:
         - db
         - redis

     db:
       image: postgres:15
       environment:
         POSTGRES_DB: myapp
         POSTGRES_USER: user
         POSTGRES_PASSWORD: pass
       volumes:
         - postgres_data:/var/lib/postgresql/data

     redis:
       image: redis:7-alpine
       ports:
         - "6379:6379"

     spark:
       image: apache/spark:3.5.3
       ports:
         - "8080:8080"
         - "7077:7077"
       environment:
         - SPARK_MODE=master
         - SPARK_RPC_AUTHENTICATION_ENABLED=no
         - SPARK_RPC_ENCRYPTION_ENABLED=no
         - SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED=no
         - SPARK_SSL_ENABLED=no

   volumes:
     postgres_data:

Development Commands
^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Build and run
   docker-compose up --build

   # Run in background
   docker-compose up -d

   # View logs
   docker-compose logs -f app

   # Stop services
   docker-compose down

Remote Development
------------------

SSH Development Setup
~~~~~~~~~~~~~~~~~~~~~

Connect to Remote Server
^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Connect to remote server
   ssh username@server.example.com

   # 2. Install SDKMAN on remote server
   curl -s "https://get.sdkman.io" | bash
   source "$HOME/.sdkman/bin/sdkman-init.sh"

   # 3. Install tools
   sdk install java 17.0.9-tem
   sdk install python 3.11.7
   sdk install spark 3.5.3

   # 4. Clone configuration
   git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
   ln -sf ~/.config/zsh/zshrc ~/.zshrc

VS Code Remote Development
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Install VS Code Remote SSH extension
   code --install-extension ms-vscode-remote.remote-ssh

   # 2. Connect to remote server
   # Use VS Code command palette: Remote-SSH: Connect to Host

   # 3. Open project on remote server
   # File -> Open Folder -> /path/to/project

   # 4. Install Python extension on remote
   # Extensions -> Python -> Install

Jupyter Remote Development
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Start Jupyter on remote server
   jupyter lab --ip=0.0.0.0 --port=8888 --no-browser

   # 2. Forward port to local machine
   ssh -L 8888:localhost:8888 username@server.example.com

   # 3. Access Jupyter from local browser
   # http://localhost:8888

CI/CD Workflows
---------------

GitHub Actions
~~~~~~~~~~~~~~

Python Application CI/CD
^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: yaml

   name: Python CI/CD

   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main ]

   jobs:
     test:
       runs-on: ubuntu-latest
       
       steps:
       - uses: actions/checkout@v3
       
       - name: Set up Python
         uses: actions/setup-python@v4
         with:
           python-version: '3.11'
       
       - name: Install dependencies
         run: |
           pip install -r requirements.txt
           pip install -r requirements-dev.txt
       
       - name: Run tests
         run: |
           pytest tests/
       
       - name: Run linting
         run: |
           black --check .
           ruff check .
       
       - name: Build Docker image
         run: |
           docker build -t myapp:${{ github.sha }} .
       
       - name: Deploy to staging
         if: github.ref == 'refs/heads/develop'
         run: |
           docker push myapp:${{ github.sha }}
           # Deploy to staging environment

Spark Application CI/CD
^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: yaml

   name: Spark CI/CD

   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]

   jobs:
     test:
       runs-on: ubuntu-latest
       
       steps:
       - uses: actions/checkout@v3
       
       - name: Set up Java
         uses: actions/setup-java@v3
         with:
           java-version: '17'
           distribution: 'temurin'
       
       - name: Set up Python
         uses: actions/setup-python@v4
         with:
           python-version: '3.11'
       
       - name: Install Spark
         run: |
           wget https://archive.apache.org/dist/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz
           tar -xzf spark-3.5.3-bin-hadoop3.tgz
           export SPARK_HOME=$PWD/spark-3.5.3-bin-hadoop3
           export PATH=$PATH:$SPARK_HOME/bin
       
       - name: Install Python dependencies
         run: |
           pip install -r requirements.txt
       
       - name: Run Spark tests
         run: |
           spark-submit --master local[*] tests/test_spark_app.py

Performance Optimization Workflows
----------------------------------

Application Profiling
~~~~~~~~~~~~~~~~~~~~~

Python Profiling
^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Install profiling tools
   uv add --dev py-spy memory-profiler

   # 2. Profile application
   py-spy record -o profile.svg -- python app.py

   # 3. Memory profiling
   python -m memory_profiler app.py

   # 4. Line-by-line profiling
   kernprof -l -v app.py

Spark Performance Tuning
^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Configure Spark for performance
   export SPARK_SQL_ADAPTIVE_ENABLED=true
   export SPARK_SQL_ADAPTIVE_COALESCE_PARTITIONS_ENABLED=true
   export SPARK_SQL_ADAPTIVE_SKEW_JOIN_ENABLED=true

   # 2. Monitor Spark UI
   # Access at http://localhost:4040

   # 3. Tune memory settings
   export SPARK_DRIVER_MEMORY="4g"
   export SPARK_EXECUTOR_MEMORY="2g"
   export SPARK_EXECUTOR_MEMORY_FRACTION=0.8

   # 4. Optimize data formats
   # Use Parquet for better compression
   # Use Delta Lake for ACID transactions

Database Optimization
^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. PostgreSQL optimization
   # Edit postgresql.conf
   shared_buffers = 256MB
   effective_cache_size = 1GB
   work_mem = 4MB
   maintenance_work_mem = 64MB

   # 2. Redis optimization
   # Edit redis.conf
   maxmemory 256mb
   maxmemory-policy allkeys-lru

   # 3. Connection pooling
   uv add sqlalchemy[pool]

Monitoring and Observability
----------------------------

Application Monitoring
~~~~~~~~~~~~~~~~~~~~~~

Logging Setup
^^^^^^^^^^^^^

.. code-block:: python

   import logging
   import structlog

   # Configure structured logging
   structlog.configure(
       processors=[
           structlog.stdlib.filter_by_level,
           structlog.stdlib.add_logger_name,
           structlog.stdlib.add_log_level,
           structlog.stdlib.PositionalArgumentsFormatter(),
           structlog.processors.TimeStamper(fmt="iso"),
           structlog.processors.StackInfoRenderer(),
           structlog.processors.format_exc_info,
           structlog.processors.UnicodeDecoder(),
           structlog.processors.JSONRenderer()
       ],
       context_class=dict,
       logger_factory=structlog.stdlib.LoggerFactory(),
       wrapper_class=structlog.stdlib.BoundLogger,
       cache_logger_on_first_use=True,
   )

   logger = structlog.get_logger()

Metrics Collection
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # 1. Install metrics tools
   uv add prometheus-client

   # 2. Collect application metrics
   from prometheus_client import Counter, Histogram, start_http_server

   # 3. Start metrics server
   start_http_server(8000)

   # 4. Access metrics at http://localhost:8000/metrics

Health Checks
^^^^^^^^^^^^^

.. code-block:: python

   from fastapi import FastAPI
   from fastapi.health import health_check

   app = FastAPI()

   @app.get("/health")
   async def health():
       return {"status": "healthy", "timestamp": datetime.utcnow()}

   @app.get("/ready")
   async def readiness():
       # Check database connection
       # Check Redis connection
       # Check external services
       return {"status": "ready"}

Best Practices
--------------

Development Practices
~~~~~~~~~~~~~~~~~~~~~

1. **Use version control** for all code and configuration
2. **Write tests** for all functionality
3. **Use linting and formatting** tools consistently
4. **Document code** with docstrings and comments
5. **Use environment variables** for configuration

Deployment Practices
~~~~~~~~~~~~~~~~~~~~

1. **Use containerization** for consistent deployments
2. **Implement health checks** for monitoring
3. **Use configuration management** for different environments
4. **Monitor performance** and optimize as needed
5. **Implement proper logging** for debugging

Security Practices
~~~~~~~~~~~~~~~~~~

1. **Use secrets management** for sensitive data
2. **Implement authentication** and authorization
3. **Use HTTPS** for all communications
4. **Regular security updates** for dependencies
5. **Audit dependencies** for vulnerabilities

.. note::

   These workflows provide comprehensive development patterns for data science, enterprise development, and system administration using the Siege Analytics ZSH Configuration System.
