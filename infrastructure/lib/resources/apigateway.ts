import { AuthorizationType, LambdaIntegration, LambdaRestApi, RequestAuthorizer, RestApi } from "aws-cdk-lib/aws-apigateway";
import { IFunction } from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";
import { BudgetBotFunctions } from "./functions";
import { uuid } from 'uuidv4';
import { Duration } from "aws-cdk-lib";

export interface ApiGatewayProps {
  webhookEntrypointFunction: IFunction,
  authorizeFunction: IFunction
}

export default class ApiGateway extends Construct {
  constructor(scope: Construct, id: string, props: ApiGatewayProps) {
    super(scope, id);

    this.createTelegramWebhookEndpoint(props.webhookEntrypointFunction, props.authorizeFunction);
  }

  private createTelegramWebhookEndpoint(handler: IFunction, authorizerHandler: IFunction) {
    const restApi = new RestApi(this, 'BotEntrypoint', {
      restApiName: 'BudgetBotApi',
    });

    const webhookResource = restApi.root.addResource('tg_webhook');
    const integration = new LambdaIntegration(handler, {
      proxy: false,
      allowTestInvoke: true,
    });

    // TODO: Need to reduce lambda calls, but it's not possible to identify 
    // Webhook requests client without calling lambda function due to Request#body identity keys location
    // Possible solution to merge routing and authorization lambdas into one
    const authorizer = new RequestAuthorizer(this, 'Authorizer', {
      handler: authorizerHandler,
      authorizerName: 'TelegramWebhookAuthorizer',
      identitySources: [],
      resultsCacheTtl: Duration.seconds(0), 
    });

    webhookResource.addMethod('POST', integration, {
      authorizationType: AuthorizationType.CUSTOM,
      authorizer: {
        authorizerId: authorizer.authorizerId,
        authorizationType: AuthorizationType.CUSTOM,
      },
    });
  }
}
