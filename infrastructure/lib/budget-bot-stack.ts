import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { Functions, ApiGateway } from './resources';


export class BudgetBotStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const botFunctions = new Functions(this, 'BotFunctions', {
      notionToken: process.env.NOTION_TOKEN as string,
      notionDatabaseId: process.env.NOTION_DATABASE_ID as string, 
      telegramToken: process.env.TELEGRAM_TOKEN as string,
      authorizedUsers: process.env.AUTHORIZED_USERS as string
    })

    const apigateway = new ApiGateway(this, 'ApiGateway', {
      webhookEntrypointFunction: botFunctions.BudgetBot
    });
  }
}
