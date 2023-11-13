// common-params.ts
import { Duration, StackProps } from "aws-cdk-lib";
import { Runtime } from "aws-cdk-lib/aws-lambda";
import { RetentionDays } from "aws-cdk-lib/aws-logs";


export const defaultRubyFunctionProps = {
    runtime: Runtime.RUBY_3_2,
    timeout: Duration.seconds(60),
    logRetention: RetentionDays.ONE_WEEK
};
  