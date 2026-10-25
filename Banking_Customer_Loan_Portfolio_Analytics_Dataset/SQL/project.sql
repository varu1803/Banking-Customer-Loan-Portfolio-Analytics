CREATE DATABASE IF NOT EXISTS banking_analytics_db;
USE banking_analytics_db;
SHOW DATABASES;


CREATE TABLE bank_customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    age INT,
    gender VARCHAR(20),
    employment_type VARCHAR(50),
    annual_income_inr DECIMAL(15,2),
    credit_score INT,
    branch_city VARCHAR(100),
    customer_since DATE
);


CREATE TABLE bank_accounts (
    account_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    account_type VARCHAR(50),
    current_balance_inr DECIMAL(15,2),
    opening_date DATE,
    account_status VARCHAR(30),

    FOREIGN KEY (customer_id)
        REFERENCES bank_customers(customer_id)
);


CREATE TABLE bank_loans (
    loan_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    loan_type VARCHAR(50),
    loan_amount_inr DECIMAL(15,2),
    annual_interest_rate_pct DECIMAL(6,2),
    tenure_months INT,
    application_date DATE,
    disbursement_date DATE NULL,
    loan_status VARCHAR(30),
    disbursed_amount_inr DECIMAL(15,2),

    FOREIGN KEY (customer_id)
        REFERENCES bank_customers(customer_id)
);


CREATE TABLE loan_payments (
    payment_id VARCHAR(20) PRIMARY KEY,
    loan_id VARCHAR(20),
    due_date DATE,
    payment_date DATE NULL,
    emi_due_inr DECIMAL(15,2),
    amount_paid_inr DECIMAL(15,2),
    payment_status VARCHAR(30),
    days_past_due INT,

    FOREIGN KEY (loan_id)
        REFERENCES bank_loans(loan_id)
);

show tables;


DESCRIBE bank_customers;

DESCRIBE bank_accounts;

DESCRIBE bank_loans;

DESCRIBE loan_payments;

USE banking_analytics_db;
SELECT COUNT(*) AS total_customers
FROM bank_customers;

SELECT COUNT(*) AS total_accounts
FROM bank_accounts;

SELECT *
FROM bank_accounts
LIMIT 5;

SELECT COUNT(*) AS invalid_customer_references
FROM bank_accounts a
LEFT JOIN bank_customers c
    ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS total_loans
FROM bank_loans;

SELECT
    loan_status,
    COUNT(*) AS total_loans,
    SUM(
        CASE
            WHEN disbursement_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_disbursement_dates
FROM bank_loans
GROUP BY loan_status;

SELECT COUNT(*) AS invalid_customer_references
FROM bank_loans l
LEFT JOIN bank_customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Rejected') AS rejected_loans
FROM banking_analytics_db.bank_loans;

SELECT
    loan_status,
    COUNT(*) AS total_loans,
    SUM(disbursement_date IS NULL) AS missing_dates
FROM bank_loans
GROUP BY loan_status;

SELECT COUNT(*) AS total_loans
FROM bank_loans;

SELECT
    COUNT(*) AS total_loans,
    SUM(loan_status = 'Rejected') AS rejected_loans,
    SUM(disbursement_date IS NULL) AS missing_dates
FROM banking_analytics_db.bank_loans;

SELECT
    COUNT(*) AS total_payments,
    SUM(payment_date IS NULL) AS missing_payment_dates
FROM loan_payments;

SELECT
    payment_status,
    COUNT(*) AS total_payments,
    SUM(payment_date IS NULL) AS missing_dates
FROM loan_payments
GROUP BY payment_status;

SELECT COUNT(*) AS invalid_loan_references
FROM loan_payments p
LEFT JOIN bank_loans l
    ON p.loan_id = l.loan_id
WHERE l.loan_id IS NULL;

SELECT 'Customers' AS table_name, COUNT(*) AS total_records
FROM bank_customers

UNION ALL

SELECT 'Accounts', COUNT(*)
FROM bank_accounts

UNION ALL

SELECT 'Loans', COUNT(*)
FROM bank_loans

UNION ALL

SELECT 'Payments', COUNT(*)
FROM loan_payments;

SELECT COUNT(*) AS invalid_loan_references
FROM loan_payments p
LEFT JOIN bank_loans l
    ON p.loan_id = l.loan_id
WHERE l.loan_id IS NULL;

SELECT
    (SELECT COUNT(*) FROM bank_customers) +
    (SELECT COUNT(*) FROM bank_accounts) +
    (SELECT COUNT(*) FROM bank_loans) +
    (SELECT COUNT(*) FROM loan_payments)
    AS total_banking_records;

SELECT
    (SELECT COUNT(*)
     FROM bank_customers) AS total_customers,

    (SELECT COUNT(*)
     FROM bank_accounts) AS total_accounts,

    (SELECT COUNT(*)
     FROM bank_loans) AS total_loan_applications,

    (SELECT COUNT(*)
     FROM bank_loans
     WHERE loan_status <> 'Rejected') AS total_approved_loans,

    (SELECT SUM(disbursed_amount_inr)
     FROM bank_loans) AS total_disbursed_amount_inr;

#Loan status distribution
SELECT
    loan_status,
    COUNT(*) AS total_loans,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM bank_loans),
        2
    ) AS percentage
FROM bank_loans
GROUP BY loan_status
ORDER BY total_loans DESC;

#Calculate loan approval and rejection rates
SELECT
    COUNT(*) AS total_applications,

    SUM(
        CASE
            WHEN loan_status <> 'Rejected' THEN 1
            ELSE 0
        END
    ) AS approved_loans,

    SUM(
        CASE
            WHEN loan_status = 'Rejected' THEN 1
            ELSE 0
        END
    ) AS rejected_loans,

    ROUND(
        SUM(CASE WHEN loan_status <> 'Rejected'
            THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS approval_rate_pct,

    ROUND(
        SUM(CASE WHEN loan_status = 'Rejected'
            THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS rejection_rate_pct

FROM bank_loans;

SELECT
    loan_type,
    COUNT(*) AS total_loan_applications,

    SUM(
        CASE
            WHEN loan_status <> 'Rejected' THEN 1
            ELSE 0
        END
    ) AS approved_loans,

    ROUND(
        SUM(disbursed_amount_inr) / 10000000,
        2
    ) AS total_disbursed_crore,

    ROUND(
        AVG(annual_interest_rate_pct),
        2
    ) AS avg_interest_rate_pct

FROM bank_loans

GROUP BY loan_type

ORDER BY total_disbursed_crore DESC;

#Loan Default Analysis by Loan Type
SELECT
    loan_type,

    COUNT(*) AS total_applications,

    SUM(
        CASE WHEN loan_status <> 'Rejected'
        THEN 1 ELSE 0 END
    ) AS disbursed_loans,

    SUM(
        CASE WHEN loan_status = 'Defaulted'
        THEN 1 ELSE 0 END
    ) AS defaulted_loans,

    ROUND(
        100.0 * SUM(
            CASE WHEN loan_status = 'Defaulted'
            THEN 1 ELSE 0 END
        ) /
        NULLIF(
            SUM(
                CASE WHEN loan_status <> 'Rejected'
                THEN 1 ELSE 0 END
            ), 0
        ),
        2
    ) AS default_rate_pct

FROM bank_loans

GROUP BY loan_type

ORDER BY default_rate_pct DESC;

#Credit Score Analysis & Loan Default Risk
SELECT
    CASE
        WHEN c.credit_score < 550 THEN 'Poor'
        WHEN c.credit_score < 650 THEN 'Fair'
        WHEN c.credit_score < 750 THEN 'Good'
        ELSE 'Excellent'
    END AS credit_score_category,

    COUNT(*) AS total_loans,

    SUM(
        CASE WHEN l.loan_status <> 'Rejected'
        THEN 1 ELSE 0 END
    ) AS disbursed_loans,

    SUM(
        CASE WHEN l.loan_status = 'Defaulted'
        THEN 1 ELSE 0 END
    ) AS defaulted_loans,

    ROUND(
        100.0 *
        SUM(CASE WHEN l.loan_status = 'Defaulted'
            THEN 1 ELSE 0 END)
        /
        NULLIF(
            SUM(CASE WHEN l.loan_status <> 'Rejected'
                THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS default_rate_pct

FROM bank_loans l

INNER JOIN bank_customers c
    ON l.customer_id = c.customer_id

GROUP BY credit_score_category

ORDER BY default_rate_pct DESC;

#Branch-wise Loan Portfolio Performance
SELECT
    c.branch_city,

    COUNT(*) AS total_loan_applications,

    SUM(
        CASE WHEN l.loan_status <> 'Rejected'
        THEN 1 ELSE 0 END
    ) AS disbursed_loans,

    ROUND(
        SUM(l.disbursed_amount_inr) / 10000000,
        2
    ) AS total_disbursed_crore,

    SUM(
        CASE WHEN l.loan_status = 'Defaulted'
        THEN 1 ELSE 0 END
    ) AS defaulted_loans,

    ROUND(
        100.0 *
        SUM(CASE WHEN l.loan_status = 'Defaulted'
            THEN 1 ELSE 0 END)
        /
        NULLIF(
            SUM(CASE WHEN l.loan_status <> 'Rejected'
                THEN 1 ELSE 0 END),
            0
        ),
        2
    ) AS default_rate_pct

FROM bank_loans l

INNER JOIN bank_customers c
    ON l.customer_id = c.customer_id

GROUP BY c.branch_city

ORDER BY total_disbursed_crore DESC;

#Monthly Loan Disbursement Trend
SELECT
    DATE_FORMAT(disbursement_date, '%Y-%m') AS loan_month,

    COUNT(*) AS total_disbursed_loans,

    ROUND(
        SUM(disbursed_amount_inr) / 10000000,
        2
    ) AS total_disbursed_crore,

    ROUND(
        AVG(disbursed_amount_inr),
        2
    ) AS avg_loan_amount_inr

FROM bank_loans

WHERE disbursement_date IS NOT NULL

GROUP BY
    DATE_FORMAT(disbursement_date, '%Y-%m')

ORDER BY loan_month;

#EMI Payment Performance Analysis
SELECT
    payment_status,

    COUNT(*) AS total_payments,

    ROUND(
        SUM(emi_due_inr) / 10000000,
        2
    ) AS total_emi_due_crore,

    ROUND(
        SUM(amount_paid_inr) / 10000000,
        2
    ) AS total_collected_crore,

    ROUND(
        100.0 * SUM(amount_paid_inr) /
        NULLIF(SUM(emi_due_inr), 0),
        2
    ) AS collection_rate_pct

FROM loan_payments

GROUP BY payment_status

ORDER BY total_payments DESC;

#Calculate overall EMI collection rate
SELECT
    COUNT(*) AS total_emi_records,

    ROUND(SUM(emi_due_inr) / 10000000, 2)
        AS total_emi_due_crore,

    ROUND(SUM(amount_paid_inr) / 10000000, 2)
        AS total_collected_crore,

    ROUND(
        100.0 * SUM(amount_paid_inr) /
        NULLIF(SUM(emi_due_inr), 0),
        2
    ) AS overall_collection_rate_pct

FROM loan_payments;

#Overdue EMI & Days Past Due Analysis
SELECT
    CASE
        WHEN days_past_due BETWEEN 1 AND 30
            THEN '1-30 Days'
        WHEN days_past_due BETWEEN 31 AND 60
            THEN '31-60 Days'
        WHEN days_past_due BETWEEN 61 AND 90
            THEN '61-90 Days'
        ELSE 'Above 90 Days'
    END AS overdue_category,

    COUNT(*) AS total_overdue_emis,

    ROUND(
        SUM(emi_due_inr - amount_paid_inr) / 10000000,
        2
    ) AS outstanding_amount_crore,

    ROUND(
        AVG(days_past_due),
        2
    ) AS avg_days_past_due

FROM loan_payments

WHERE payment_status = 'Overdue'
    AND days_past_due > 0

GROUP BY overdue_category

ORDER BY MIN(days_past_due);

#Top 10 Customers by Loan Disbursement
SELECT
    c.customer_id,
    c.customer_name,
    c.branch_city,

    COUNT(l.loan_id) AS total_disbursed_loans,

    ROUND(
        SUM(l.disbursed_amount_inr) / 100000,
        2
    ) AS total_disbursed_lakh,

    ROUND(
        AVG(l.annual_interest_rate_pct),
        2
    ) AS avg_interest_rate_pct

FROM bank_customers c

INNER JOIN bank_loans l
    ON c.customer_id = l.customer_id

WHERE l.loan_status <> 'Rejected'

GROUP BY
    c.customer_id,
    c.customer_name,
    c.branch_city

ORDER BY total_disbursed_lakh DESC

LIMIT 10;
