# AI_qa(AI_Helper) 
## Change
* ### unimeal_backend\requirements.txt
1. pydantic==2.12.5
2. google-genai==2.22.0

* ### unimeal_backend\app\schemas.py

* ### unimeal_frontend\src\views\AiHelperView.vue
1. Change AI display to Gemini
2. Change the layout

* ### unimeal_backend\app\models.py

* ### unimeal_backend\app\services\recipe_service.py


## New file
* ### unimeal_backend\app\routers\aiHelper.py
* ### ai_qa\README.md
* ### ai_qa\healthyCheck.py
* ### .venv(python 3.13)
* ### unimeal_backend\app\services\aiRecommendation.py
* ### unimeal_backend\app\services\query_parser.py

## Start
* ### python_requirements
  python 3.13
  1. open cmd in the 13_unimeal root directoryand type (.\.venv\Scripts\activate) to enter(.venv)
  2. type following commands in the cmd to install requirements
    ```python
        py -m pip install --upgrade pip
        py -m pip install -r unimeal_backend\requirements.txt
    ```
--------------------------------------------------------------
* ### HEALTHY CHECK
  1. Create a .env in the 13_unimeal root directory
  2. Fill it in according to .env.example, and also enter your own GEMINI key
  3. Run ```python ai_qa/healthyCheck.py ```in the 13_unimeal root directory to run the healthy check
--------------------------------------------------------------
