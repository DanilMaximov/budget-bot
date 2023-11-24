import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { Functions, ApiGateway, Database } from './resources';
import { AuthorizeFunction } from './resources/functions/authorize-function';
import * as ssm from 'aws-cdk-lib/aws-ssm';


export class BudgetBotStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const db = new Database(this, 'Database');  

    const botFunctions = new Functions(this, 'BotFunctions', {
      notionToken: process.env.NOTION_TOKEN as string,
      notionDatabaseId: process.env.NOTION_DATABASE_ID as string, 
      telegramToken: process.env.TELEGRAM_TOKEN as string,
      authorizedUsers: process.env.AUTHORIZED_USERS as string
    })

    const authorizeFunction = new AuthorizeFunction(this, 'AuthorizeFunction', {
      authorizedUsers: process.env.AUTHORIZED_USERS as string,
      webhookSecret: this.getWebhookSecret()
    });

    const apigateway = new ApiGateway(this, 'ApiGateway', {
      webhookEntrypointFunction: botFunctions.BudgetBot,
      authorizeFunction: authorizeFunction.func,
    });
  }

  private getWebhookSecret = (): string => ssm.StringParameter.valueForStringParameter(this, 'webhook_secret');
}
