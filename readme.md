# SV Performance Test Harness for AWS

These scripts allow to automatically test SV performance using predefined virtual services on predefined AWS Instance Types with different count of users using JMeter. The goal is to find optimal and maximal TPS along with wide range of other metrics for given AWS instance type and virtual service.

The motivation for the scripts was to speedup time consuming manual work needed to achieve finding optimal and maximal TPS on different environments with different virtual services.

Current version of the test harness allows to test SV Server in the Docker on Linux. Helper scripts on your machine are Windows batch files.

## Architecture

The test is executed from JMeter EC2 machine against SV Server EC2 machine. SV Server EC2 machine is created automatically by the script, so different instance types can be automatically tested.

The main script contains 3 nested loops:
  1. Outermost loop iterates over list of instance types defined in `upload-to-jmeter-machine/test-instance-types.txt`
  1. First nested loop iterates over virtual services to test which are defined in `upload-to-jmeter-machine/test-services.txt`
  1. Second nested loop sets increasing number of users (AKA threads) starting from one user and increasing by 10% with every iteration. The number of iterations is dynamic and depends on the current instance type and virtual service. The script first detects when TPS for current number of users is less then previous maximum. This means that the CPU is overloaded and is not in the healthy territory anymore. Once this is reached additional 10 iterations are performed to collect data on even more overloaded configuration.

## Setup

### Prerequisites

1. Install and add https://www.putty.org/ and add `putty` and `pscp` on the Windows path, so you can run `.bat` helper scripts.

### Create SV Server AMI

1. Create new EC2 machine (the setup was tested in `Amazon Linux 2023`).
1. Copy `env-template.bat` to `env.bat` and configure environment variables in it. Set:
   - `SV_SERVER_HOST` to the public hostname of EC2 machine
   - `CERTIFICATE_PPK` and `CERTIFICATE_PEM` to the value of your key you used to create the EC2 machine
1. Run `upload-to-sv-machine.bat` to get content of `upload-to-sv-machine` to your new EC2 machine
1. Login to the EC2 machine with `putty-sv-server.bat`
1. Run `install.sh` to install Docker and other prerequisites.
1. Re-login
1. Customize `docker-compose.yaml`. For example you can enabled/disable `inMemory` simulation. Use RDS DB and so on.
1. Run `docker compose up`
1. Login to APLS server and provide valid license
1. Once your SV Server is running is intended, create new AMI and note it's ID

### Create Security Group for SV Server AMI

Create SG for the SV Server AMI and note the ID. The SG must allow traffic from JMeter machine and optionally from/to other sources depending on your setup.

### Create AWS User

This AWS user will be used to create EC2 machine and to read various metrics via `aws` CLI.

1. Create new user via e.g. https://us-east-1.console.aws.amazon.com/iamv2/home
1. Create access key and secret key
1. Add following permissions for the user:
   - AmazonEC2FullAccess
   - AmazonRDSFullAccess
   - AmazonRDSPerformanceInsightsFullAccess
   - PowerUserAccess   

### Create JMeter EC2 machine

1. Create another EC2 machine.
1. Configure environment variables in `env.bat` and set 
   - `JMETER_HOST` to the public hostname of the EC2 machine
1. Run `upload-to-jmeter-machine.bat`
1. Run `putty-sv-server.bat`
1. Configure `test-services.txt`
    - use '#' to comment out the virtual service you don't want to include in the test
	- provide optional data model and performance model IDs like `{vs-name} {dm-id} {pm-id}`. E.g. `member-accounts-soap 7697cb2a-14e6-4fae-994b-0bf09adbaa25 406f14f4-c921-4237-8b38-e813f9809db1`
1. Configure `test-instance-types.txt` according to your needs
    - use '#' to comment out the instance type you don't want to include in the test

### Providing custom VS and JMeter scripts

You need to honor below naming convention as the only information script gets is the virtual service name from `test-services.txt`.

1. Define virtual service name {vs-name}
1. Create a SV project {vs-name} and a virtual service with {vs-name}. The resulting .vs file should be at following path: `virtual-services/{vs-name}/{vs-name}/{vs-name}.vs`
1. Create an associated JMeter test with filename {vs-name}.jmx and put it to `jmeter-tests` folder. The resulting path should therefor be `jmeter-tests/{vs-name}.jmx`
Virtual service must be uploaded to upload-to-jmeter-machine\virtual-services\
1. Define your VS in `test-services.txt`

## Running the test

Login to JMeter machine and run `run-jmeter-test.sh` with following parameters:

CLI parameters:

`./run-jmeter-test.sh {AMI_ID} {SG_ID} {KEY_NAME} {NOTE}`

Example of the CLI

`./run-jmeter-test.sh ami-06f0ecfda9269eff4 sg-0a97cc79e157dbbd0 james-key-2021-11-04 "testing MemberAccounts with inMemory on RDS"`

## Test result

Test result are collected in CSV file named `results.csv`

Folder `/results/` contains two examples of gathered results:

### `results-2023-09-04-builtin-vs.xlsx`
Contains result of SOAP and REST demo service and a portfolio-suggestion REST service used in the [SV Training](https://github.com/MicroFocus/sv-trainings). Amount of gathered data is low as this data are from the early versions of the test harness.

Following table summarizes peak TPS on different AWS instance types:

|                       | member-accounts-binary-test.jmx | member-accounts-soap-test.jmx | portfolio-suggestion-rest-test.jmx |
|-----------------------|--------------------------------:|------------------------------:|-----------------------------------:|
| c6i.2xlarge (8 CPUs)  |                           8 142 |                         7 254 |                                508 |
| c6i.4xlarge (16 CPUs) |                          15 033 |                        13 077 |                              1 007 |
| c6i.8xlarge (32 CPUs) |                          25 258 |                        24 935 |                              1 949 |
| c6i.large (2 CPUs)    |                           2 246 |                         1 848 |                                125 |
| c6i.xlarge (4 CPUs)   |                           4 521 |                         3 839 |                                256 |
| t2.2xlarge (8 CPUs)   |                           4 781 |                         4 593 |                                447 |
| t2.large (2 CPUs)     |                           1 863 |                         1 516 |                                121 |
| t2.medium (2 CPUs)    |                           1 852 |                         1 566 |                                 52 |
| t2.xlarge (4 CPUs)    |                           3 484 |                         2 804 |                                249 |

### `results-2023-10-04-user-redacted.xlsx`
Contains results of one user virtual service with and without performance model on two different instances. Excel file contains also charts. Amount of gathered data is quite high since the test used newer version of test harness.

|             | With Performance Model | Without Performance Model |
|-------------|-----------------------:|--------------------------:|
| c6i.2xlarge |                  3 239 |                     4 072 |
| c6i.4xlarge |                  4 112 |                           |

## Collected Data

Used schortcuts in the CSV column names:
- JM - JMeter
- SVS - SV Server
- DM - Data Model
- PM - Performance Model
- CW - CloudWatch
- PI - Performance Insights

Following data are collected:

- Start Time
- End Time
- JM Test
- JM Think Time
- JM Threads
- JM CPU Loadavg Max
- DB
- DB Type
- DB Connection String
- DB TXs
- DB TX/s
- SVS Docker
- SVS Version
- SVS Data Provider
- VS ID
- VS Name
- VS Protocol ID
- VS DM ID
- VS PM ID
- VS DM Accuracy
- VS PM Accuracy
- SVS CPU Model
- SVS Hypervisor Vendor
- SVS OS
- SVS Errors
- SVS CPU Loadavg Max
- SVS CPU Utilization (loadavg)
- SVS CPU Utilization (SV API)
- SVS DB Response Time
- Note
- JM TPS
- JM Requests
- JM RT Min
- JM RT Max
- JM RT Avg
- JM Std Dev
- JM Errors
- JM Req Bytes Avg
- JM Res Bytes Avg
- JM In MB/s
- JM Out MB/s
- JM In MB
- JM Out MB
- JM Instance Type
- JM CPU Count
- JM RAM
- JM Public IP
- JM AMI ID
- JM AMI Platform
- JM AMI Description
- JM CPU Utilization (CW)
- JM Net In MB/s (CW)
- JM Net Out MB/s (CW)
- JM Net In MB (CW)
- JM Net Out MB (CW)
- SVS Instance Type
- SVS CPU Count
- SVS RAM
- SVS Public IP
- SVS AMI ID
- SVS AMI Platform
- SVS AMI Description
- SVS CPU Utilization (CW)
- SVS Net In MB/s (CW)
- SVS Net Out MB/s (CW)
- SVS Net In MB (CW)
- SVS Net Out MB (CW)
- DB Instance Type
- DB CPU Count
- DB RAM
- DB Public IP
- DB AMI ID
- DB AMI Platform
- DB AMI Description
- DB CPU Utilization (CW)
- DB Net In MB/s (CW)
- DB Net Out MB/s (CW)
- DB Net In MB (CW)
- DB Net Out MB (CW)
- RDS Instance Type
- RDS CPU Count
- RDS RAM GB
- RDS CPU Utilization (CW)
- RDS ReadIOPS Avg (CW)
- RDS ReadIOPS Max (CW)
- RDS WriteIOPS Avg (CW)
- RDS WriteIOPS Max (CW)
- RDS DB Transactions (PI)
