#!make
include ../.env

deploy:
	../bin/package
	aws-vault exec pet-project-dev --no-session -- cdk deploy 
set_webhook: 
	UUID=$(eval UUID=$(shell uuidgen))

	@curl --silent https://api.telegram.org/bot${TELEGRAM_TOKEN}/deleteWebhook; echo
	@curl --silent -F "url=${TELEGRAM_WEBHOOK_URL}" -F "allowed_updates=%5B\"message\"%5D" -F "secret_token=$(UUID)" \
		https://api.telegram.org/bot${TELEGRAM_TOKEN}/setWebhook; echo
	aws-vault exec pet-project-dev --no-session -- aws ssm put-parameter --name "webhook_secret" --type "String" --value "${UUID}"
