import { StackProps } from "aws-cdk-lib";
import { Code, Function } from "aws-cdk-lib/aws-lambda";
import { Construct } from "constructs";
import { defaultRubyFunctionProps } from "./default-function-props";
import { join } from "path";


export interface AuthorizeFunctionProps extends StackProps {
  authorizedUsers: string,
  webhookSecret: string
}

export class AuthorizeFunction extends Construct {
  readonly func: Function;
  private props: AuthorizeFunctionProps;

  constructor(scope: Construct, id: string, props: AuthorizeFunctionProps) {
    super(scope, id);

    this.props = props
    this.func = this.createAuthorizeFunction();
  }

  private createAuthorizeFunction(): Function {
    return new Function(this, 'AuthorizeFunction', {
      ...defaultRubyFunctionProps,
      code: Code.fromAsset(join(__dirname, '../../package/authorize.zip')),
      handler: 'handler.Authorizer.handler',
      environment: {
        AUTHORIZED_USERS: this.props.authorizedUsers,
        TELEGRAM_WEBHOOK_TOKEN: this.props.webhookSecret,
      },
    });
  }
}
