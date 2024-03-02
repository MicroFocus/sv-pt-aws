#  Service Virtualization performance testing introduction

## Motivation

Recently, we have been getting a lot of queries on Service Virtualization use in performance testing, especially in AWS environments. In this repository, we put together a collection of useful information, best practices, and reference performance test scripts, which you can run as a benchmark, or use as a starting point for designing a more specific performance test that will suit your specific needs. On this page, you will find practical recommendations, explanations of basic concepts and common mistakes.

>### Example
> You have a virtual service which needs 10 ms of CPU time (AKA Response Time) to calculate a response and a 2 CPU-core SV server machine. 
>
>This means you should theoretically achieve:
> - at maximum 100 TPS with 1 user and 0 Think Time - CPU utilization should be 50% with 1 user on 2 CPU machine<br/>`single_user_max_tps = 1000 / (response_time + think_time) = 1000 / (10 + 0) = 100 TPS`
> - at maximum 100 TPS with 2 users and 10 ms Think Time - you can trade users for Think Time to achieve the same TPS<br/>`tps = user_count * 1000 / (response_time + think_time) = 2 * 1000 / (10 + 10) = 100 TPS`
> - at maximum 10 TPS with 20 users and 1990 ms Think Time - another example of trading users for Think Time<br>`tps = user_count * 1000 / (response_time + think_time) = 20 * 1000 / (10 + 1990) = 10 TPS`
> - at maximum 200 TPS with 2 users and 0 ms Think Time - this should max out the CPU at 100% since you have 2 users on a 2 CPU machine (and no Think Time)<br/>`max_tps = user_count * 1000 / (response_time + think_time) = 2 * 1000 / (10 + 0) = 200 TPS`
> - sub 200 TPS with 3 user and 0 ms Think Time - by adding more users than the CPU core count you overload the SV Server and your TPS will drop below the theoretical maximum. Also, the Response Time will climb up to compensate for the additional load. Never get into this situation. Actually, always keep the CPU utilization below 80% to get reproducible results.
>
> If you don't understand, continue reading. 

## Use cases

These are the scenarios we encounter most frequently:

- SV is involved as a dependency of the tested system under load. The Dev team deploys LoadRunner (JMeter, or a similar tool…) to generate load on the tested system, which uses virtual services during the processing (instead of using the real endpoints, which are harder to control). 

    > **Note:** Having the dependencies virtualized means you can tweak their Response Time to analyze their actual impact on the overall system execution. You can test the impact of having them really fast or slow. This is how you can discover real bottlenecks or test how resilient your system is. 

- The Dev team generates the load directly to the SV Server to test its ability to meet the required performance criteria to make sure they have selected the correct hardware configuration, for example, the correct AWS instance type and network settings for more complex testing in the future.

    > **Note:** If you use the SV licensing per SV server instance (and not per virtual service instance), you will be motivated to deploy as many virtual services as possible into a single machine and you will need to get the machine sizing right. When using the SV licensing per virtual service instance, you can distribute the virtual services among as many machines as you want, in which case you can also distribute the load to many less powerful machines (since the total number of services running in simulation is what counts here, not the number of machines). 

## Parameters to measure and optimize

> It is important that you measure the CPU and memory utilization, as well as the number of TCP connections and the network parameters on the SV Server, the database machine, and also on the load generator machine (the client). Many issues described in this document originate in one of these components but manifest in another one. If you need to understand an issue, you need to collect statistics about all the components involved.

### Response Time
We recommend that you measure the Response Time outside performance tests, perhaps on the SV Designer’s Embedded Server. This will give you an idea about the pure CPU processing time needed to produce a response.

> Always measure some n-th generated response, not the first one to allow for some warm-up period of the SV Server and other components involved. 

During a performance test on the SV Server, you should initially see a bit lower Response Time compared to the one measured on the Embedded Server. When you gradually increase the load, the Response Time will initially remain about the same, while the TPS (transactions/requests processed per second) will gradually increase until the CPU gets 100% utilized. After this point, you will see also the Response Time increase on the SV Server, since the CPU on the SV Server will get over-utilized and a backlog of responses will start building up. Having increased the load even further the communication may begin timing out before responses get produced. 

If you see a higher Response Time without the CPU being overloaded, this may hint at high network latency or an issue with some middle component (like some proxy). Outside a load test, the Response Time measured on the SV Standalone Server should always stay a bit lower than on the SV Designer’s Embedded Server. But if that’s not the case, some other component is almost always to blame - it is extremely unlikely to be a defect in the SV code base since exactly the same code runs on the Embedded and the Standalone SV Server.

> #### <a id="hints"></a>Hints to improve Response Time
>
> These are some ways to reduce the Response Time:
> - Push back whenever people want you to implement a more complex and sophisticated virtual service design than actually needed (especially during a migration from a competitor product). This happens very often and avoiding it will save you significant design and troubleshooting effort. Do analyze the required simulated behavior beforehand and propose the least complex solution that will meet the required parameters. 
> - The simpler and smaller the Data Model, the faster it will perform. Avoid data duplication when possible. For instance, avoid having the same value populated in the same column for thousands of Data Model rows, but rather split the data into multiple Data Rules (several rows each) covering all the required combinations of values without explicitly specifying them. 
> - Sometimes C# scripting or an external service call (SCA) will help you avoid specifying all combinations of column values in thousands of recorded or imported Data Model rows, which will make the Data Model smaller. But never optimize prematurely, always redesign your virtual services only when you know for sure you will face performance issues otherwise.
> - Use C# scripting, instead of JavaScript scripting. 
> - If you use C# scripting, switch the C# security sandbox off as explained [here](https://admhelp.microfocus.com/sv/en/2023-2023-r1/Help/Content/UG/t_scripted_rule_Csharp.htm#mt-item-2). 
> - Never ever have the Message Logging turned on during performance tests, under any circumstance, for any reason. Logging of debugging information in performance tests will make the SV Server perform much slower, it may clutter your database with huge amounts of data, and it will always make all the measured statistics and metrics not representative and thus invalid.
> - Make sure your service doesn’t log a lot of warnings, errors, or similar messages to the Problem List, or to the SV Server text log file (HP.SV.StandaloneServer.log). This may also have a significant effect on performance, especially if you log something for every other request.
> - Amend your Data Models to avoid logging warnings to the Problem List due to unknown structures or missing fields. Alternatively, reconfigure the log4net log levels in the HP.SV.StandaloneServer.exe.config file to avoid excessive logging (SV Server restart is not needed in such cases). The name of the log4net logger is prepended to every log entry in the SV Server log file. See any Log4Net documentation for details.
> - Select the "None" Performance Model before switching your virtual services to Simulation. In this case, SV will skip altogether any functionality that would add an additional delay to the pure SV processing time. Note that in such cases, Response Delay overrides in your Data Model will not work, along with any other Performance Model-related settings. SV will simply generate the response as fast as it can. 
> - Turn on the in-memory simulation. In such a case, SV will cache a lot of DB query results to memory upfront. In this way, you will trade a higher RAM utilization for a lower CPU utilization and DB IOPs. After the change, the throughput increase may increase anywhere from 10% to 100% (depending on the data model structure). Please follow [this article](https://admhelp.microfocus.com/sv/en/2023-2023-r1/Help/Content/Installation/Service%20Virtualization%20Server/Standalone_Config.htm#mt-item-3) to turn the in-memory simulation on. 

### Transactions per second (TPS)

> #### TPS or TPM (transactions per second, or transactions per minute) 
> This is the number of requests processed by your virtual service per unit of time. Alternatively, you can understand it as the number of responses per unit of time the measured virtual service was able to produce.

When measuring TPS consider the following recommendations:
- You must know how the TPS metric is measured and choose the right granularity of aggregation. The aggregation interval must be much shorter than the length of the overall test. 

    > For instance, if your performance test takes 15 minutes to finish but you aggregate the TPS per hour, then 1000 TPS will appear as 250 TPS in your report since the hardware was idle for 45 minutes  of the interval of aggregation.
- At the beginning of the performance test, the same hardware resources are usually used to deploy virtual services that will later be used to process your requests. You must ensure this initial phase is not counted when aggregating intervals to calculate TPS. Do filter out these initial intervals of aggregation, similarly make sure you don’t include the intervals at the end of the test, which may not be representative since the system was already "cooling down".
- To meet a certain TPS, you must make sure you generate enough requests per unit of time. If the required TPS is 1000, you must be able to generate more than 1000 requests per second from your load generators on the client machine, otherwise, the virtual service will obviously never respond with 1000 or more responses per second. Also, make sure no other component involved causes a slowdown of the load generation.   
- A good performance test must be repeatable and produce similar results. You must make sure your hardware resources are not shared with other teams when running performance tests, otherwise the measured statistics will not be representative.

### CPU Utilization

Measuring CPU utilization is not straightforward. In case of CPU utilization under 100%, if the sampling interval is right and the aggregation interval is right, you can often correctly estimate how much of the time a CPU core was idle or working. But for values above 100%, there is a queue of tasks waiting to be processed by the CPU and there is no intuitive or exact way to convert the length of the queue to a percentage number above 100, thus such values cannot be relied on.

### IOPs and memory utilization

SV Server always works against an external database. A properly configured database will cache the frequently accessed data to the operating memory, so it is very unlikely you would ever face high IOPs on the database server or the SV Server. 
If you do face high IOPs, most likely your DB or the SV Server machine are low on RAM and have to swap data to disk frequently. 
Alternatively, you may be unknowingly logging a lot of data to the Message Log, the Problem List, or the SV server log file.

## Network throughput and the number of TCP connections

Consider measuring the network speed and latency, as well as the number of open TCP connections. If the client machine is unable to handle the responses fast enough, the number of open connections may start leaking above the OS limits (more connections open for requests than closed after receiving responses). In this case, what appears to be a network issue may actually be a client-machine issue. This is why it is convenient to monitor the parameters of all the involved components.

Similar issues may appear in the Stand-by (Passthrough) mode when the real service is slow to produce responses and the SV Server has to keep a number of connections open waiting for responses of the real service to be forwarded to clients.

>If the real service processing fails hard, perhaps on the TCP level, SV sometimes can't replicate/forward the same kind of technical failure and the error will appear on the client side as a different error. E.g. instead of the TCP level error, the load generator machine may experience "504 Bad Gateway".

## Designing the performance test

These are the recommended steps to follow:
- Start by getting the requirements in terms of TPS for each virtual service involved in the performance test<br/>`vs1_required_tps, vs2_required_tps, ...`
- Once you know the required TPS, measure each virtual service Response Time (in milliseconds) with a single request and a single user<br/>`vs1_rt, vs2_rt, ...`
- Once you have measured the virtual service Response Time, calculate the theoretical TPS maximum for each virtual service using<br/>`vs1_maximum_tps = cpu_count * 1000 / vs1_rt, ...`
- Calculate the expected CPU utilization<br/>`vs1_required_tps/vs1_maximum_tps + vs1_required_tps/vs1_maximum_tps + ...`
- If you calculated more than 100% CPU utilization in the previous step, you will either need to boost your CPU or speed up your virtual services.
- Once you think you have the parameters right (theoretically), do the real measurement. Keep an eye on the CPU utilization and make sure it never climbs above 80%, otherwise you may not get reproducible results.
- If your CPU utilization climbs over 80% on the SV Server, add more CPU resources, or optimize your virtual services - see [Hints to improve Response Time](#hints)
- You should also keep an eye on all other components involved in the load test, like the load generators, SV DB, network, and disk. Optimize or boost the respective component parameters when necessary.

## Frequent issues and misconceptions

The Dev team is usually given performance parameters to meet, but very often the requirements are incomplete. You can only get a meaningful insight into performance-related matters if you understand the influence factors and relations between them.

### Number of users means nothing without Think Time specified

The number of users sending requests in parallel is never the complete information to work with. You must understand that every hardware resource is capable of a certain degree of parallelization, expressed usually as the number of virtual CPU cores. With 16 cores, 16 users will utilize the CPU 100% whenever they produce request after request without any delay. Therefore you have to always specify also the Think Time, which is the delay between individual requests. With zero Think Time even a very powerful machine with tens of CPU cores will never be able to serve more than tens of users at a time (in parallel). 

>#### Specifying Think Time
>Think Time can be specified as a parameter of the load generator tool of your choice (LoadRunner, JMeter…). 
<BR><BR>*Note: Using the Response Delay in a Performance Model on the SV side can have a somewhat similar effect but only in case the load generator tool waits for a response before sending another request.*

<BR>

>#### SV Server 'works faster' on a slower network
> It takes some time for the SV Server to produce a response, and it takes some more time for the response to reach the client application over the network. A poorer network with a higher latency sometimes brings in a natural "Think Time" and you may be under the impression that the SV Server is capable of handling more users on a slower network than on a faster one. This is just an illusion, you need to apply the right Think Time.

<BR>

>#### Number of users calculation
>
>The following formula summarizes the relation between the Response Time, Think Time, and the Number of Concurrent Users that will fully utilize the CPU: 
>
> **Max Users = CPU Cores / Response Time * (Response Time + Think Time)**<BR>
>TPS SVC = CPU Cores / Response Time [in seconds] <BR>
>TPS USR = 1 / (Response Time + Think Time) [in seconds]
>
>
> **Max Users** = The number of users that will fully utilize the CPU<BR>
> **Response Time** = The time it takes to generate a single response without handling any other load.<BR>
> **Think Time** = The wait time between individual requests.<BR>
> **CPU Cores** = The degree of parallelization, usually the number of virtual CPU cores the machine has.<BR>
> **TPS USR** = The requests per second generated from the client machine (from the load generator)<BR>
> **TPS SVC** = The requests per second served by the virtual service in total.
>
>|CPU Cores|Response Time|Think Time|Max Users|TPS USR|TPS SVC|
>|---------|-------------|----------|---------|-------|-------|
>|1|50|0|1|20.00|20.00|
>|1|50|50|2|10.00|20.00|
>|1|50|100|3|6.67|20.00|
>|2|50|0|2|20.00|40.00|
>|2|50|25|3|13.33|40.00|
>|2|50|50|4|10.00|40.00|
>|2|50|100|6|6.67|40.00|
>|16|50|0|16|20.00|320.00|
>|16|50|25|24|13.33|320.00|
>|16|50|50|32|10.00|320.00|
>|16|50|100|48|6.67|320.00|
>|16|50|1000|336|0.95|320.00|
>
><BR>***Comment**: If it takes 50 ms for your virtual service to produce a single response without handling any other load, you can serve 16 users on a 16-core machine with zero Think Time and fully utilize the CPU, or 32 users with 50 ms Think Time or 336 users with 1000 ms Think Time to achieve 100% CPU. <BR> Thus you should never ask "How many users can the SV server handle?", it is like asking "How many guests can a restaurant handle?" - the time dimension is completely missing from the picture. Even if you ask about "concurrent users", the answer is always "too low" for practical use, as it is the number of virtual CPU cores (the degree of parallelism).*

### 'Invisible' CPU load peaks

If the load on the SV Server is uneven, the SV Server may time out because its CPU is overloaded. If the load is significantly uneven, you may even face time-outs without seeing a high CPU utilization in your CPU utilization measurements. 

The measured CPU utilization is always averaged per a time interval (3 or 5 minutes, sometimes even more); if the load peak is much shorter than the aggregation interval, the peaks will be averaged and impossible to see on the given level of aggregation granularity. 

>#### Review the architecture of the system under test
>Once you have configured the right aggregation intervals for the measured values and possibly also increased the time out on the interfaces, you may decide to use a more powerful AWS instance type, but consider also questioning the technical architecture of the tested system itself. 
>
>For instance, REST services may not be a good choice for handling significant peaks in request processing, a more queue-oriented protocol may distribute the load peaks more evenly among multiple response generators. 
>
>>*Let's suppose there is already a layer of queue 
processing behind your REST services. In that case, you may consider virtualizing the queue processing layer (rather than the REST interface), instead of upsizing the SV Server, or even trying to introduce a load balancer between multiple SV Servers, or any kind of auto-scaling.*
>

### Client-side errors in SV log files

Even if the SV Server is capable of withstanding the load, still you may see errors in the SV Server log file due to client-side failures (these are not 'SV defects').

When the client machine (the load generator tool) is not capable of handling the responses fast enough, receiving responses on the client machine may time out. Very often the load generators swallow the exception and don't log anything (they don't care about responses, since their primary purpose is to generate requests). This often manifests in the SV Server log file as similar errors:
- "broken pipe"
- "connections reset by peer"
- "operation was attempted on a nonexistent network connection" 
<BR><BR>
> #### Always Monitor the Load Generator Machine and Consider Upsizing
> You should always measure the resource utilization of the client machine generating the load, since receiving responses may actually be more resource-intensive for it than generating requests.
>
> You should also never suppress logging errors on the client side. 
>
> Sometimes other components are involved, like a slow network or various proxies. Depending on your toolset, the load generator process running on the client machine may ignore its own errors from response processing, but errors will still show up in the SV Server log file (these are not 'SV defects'). 
>
>**In such cases upsizing the SV Server will not help (accidentally quite the opposite would "help"), but it will help to upsize the client machine, use a different, faster, more direct network, or configure the proxy components properly (e.g. MuleSoft).**

<BR>

>#### Errors in SV log due to forcibly-ended load generation
>Errors similar to "broken pipe", "connections reset by peer", and "operation was attempted on a nonexistent network connection" show up in the SV Log also when you interrupt the load test before all the responses have been processed on the client machine (e.g. by clicking the Stop button in JMeter, which will immediately reset all the open TCP connections).
