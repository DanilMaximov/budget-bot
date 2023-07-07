import {
	AttributeType,
	BillingMode,
	type ITable,
	Table,
} from "aws-cdk-lib/aws-dynamodb";
import { Construct } from "constructs";

export default class Database extends Construct {
	public readonly expensesTable: ITable;

	constructor(scope: Construct, id: string) {
		super(scope, id);

		this.expensesTable = this.createExpensesTable();
	}

	private createExpensesTable(): ITable {
		const baseTable = new Table(this, "budget-expenses", {
			tableName: "expenses",
			partitionKey: {
				name: "category",
				type: AttributeType.STRING,
			},
			sortKey: {
				name: "date",
				type: AttributeType.STRING,
			},
			billingMode: BillingMode.PAY_PER_REQUEST,
		});

		return baseTable;
	}
}  
