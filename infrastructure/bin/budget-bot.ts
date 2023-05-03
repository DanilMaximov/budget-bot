#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import * as dotenv from 'dotenv';
import { BudgetBotStack } from '../lib/budget-bot-stack';

dotenv.config({ path: __dirname + '/../../.env' })

if(!process.env.NOTION_TOKEN || !process.env.NOTION_DATABASE_ID || !process.env.TELEGRAM_TOKEN || !process.env.AUTHORIZED_USERS) {
  throw new Error("Missing environment variables. Please check your .env file.")
}

const app = new cdk.App();
new BudgetBotStack(app, 'BudgetBotStack');
