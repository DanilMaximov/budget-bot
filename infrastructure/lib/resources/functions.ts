import { Duration, StackProps } from "aws-cdk-lib";
import { Code, Runtime, Function, IFunction } from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";
import { Charset, LogLevel, NodejsFunction, OutputFormat, SourceMapMode } from "aws-cdk-lib/aws-lambda-nodejs";
import { RetentionDays } from "aws-cdk-lib/aws-logs";
import { join } from "path";
import * as ssm from 'aws-cdk-lib/aws-ssm';


export interface FunctionsProps extends StackProps {
    notionToken: string
    notionDatabaseId: string
    telegramToken: string
    authorizedUsers: string
}

export type BudgetBotFunctions = {
    BudgetBot: Function
}

export default class Functions extends Construct {
  readonly BudgetBot: Function;

  private props: FunctionsProps;

  constructor(scope: Construct, id: string, props: FunctionsProps){
    super(scope, id);    

    this.props = props
    this.BudgetBot = this.createBudgetBot();
  }

  private createBudgetBot() : Function { 
    const webhookToken = ssm.StringParameter.valueForStringParameter(this, 'webhook_secret');

    const BudgetBotProps = {
      code: Code.fromAsset( `../package/package.zip`),
      handler: 'handler.handler',
      runtime: Runtime.RUBY_2_7,
      timeout: Duration.seconds(60),
      logRetention: RetentionDays.ONE_WEEK,
      environment: {
        NOTION_TOKEN: this.props.notionToken,
        NOTION_DATABASE_ID: this.props.notionDatabaseId,
        TELEGRAM_TOKEN: this.props.telegramToken,
        TELEGRAM_WEBHOOK_TOKEN: webhookToken,
        AUTHORIZED_USERS: this.props.authorizedUsers
      }, 

    }
    
    const BudgetBot = new Function(this, 'BudgetBot', BudgetBotProps);
    
    return BudgetBot;
  }
}