import { LambdaIntegration, LambdaRestApi, RequestAuthorizer } from "aws-cdk-lib/aws-apigateway";
import { IFunction } from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";
import { BudgetBotFunctions } from "./functions";
import { uuid } from 'uuidv4';

export interface ApiGatewayProps {
    webhookEntrypointFunction: IFunction
}

export default class ApiGateway extends Construct {    
  constructor(scope: Construct, id: string, props: ApiGatewayProps){
    super(scope, id);

    this.createWebhookEndpoint(props.webhookEntrypointFunction);
  }

  private createWebhookEndpoint(webhookEntrypoint: IFunction) {
    const apigw = new LambdaRestApi(this, 'BotEntrypoint', {
        restApiName: 'BudgetBotApi',
        handler: webhookEntrypoint,
        proxy: false
    });

    const webhookApiIntegration = new LambdaIntegration(webhookEntrypoint);

    apigw.root
        .addResource('tg_webhook')
        .addMethod('ANY')
  }
}
