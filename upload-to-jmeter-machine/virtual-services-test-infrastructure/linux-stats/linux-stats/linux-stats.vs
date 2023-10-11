<?xml version="1.0" encoding="utf-8"?>
<vs:virtualService version="5.9.0.1616" id="3f2fdfae-b7ff-4844-af6b-5da8caae47ed" name="linux-stats" description="REST virtual service for getting various data of a linux OS SV Server is running on." activeConfiguration="4303060e-f233-4c7a-a7b4-bddf4b6f355c" nonExistentRealService="true" lastModifier="Jakub" lastModification="63831234395175" xmlns:vs="http://hp.com/SOAQ/ServiceVirtualization/2010/">
  <vs:projectId ref="{988588F6-195E-4601-AF07-AD0F92DC27EF}" />
  <vs:projectName>linux-stats</vs:projectName>
  <vs:serviceDescription ref="f27bb099-fa5f-41b3-b85c-7ae04e7e5de6" />
  <vs:virtualEndpoint type="HTTP" address="/linux-stats" realAddress="" isTemporary="false" isDiscovered="false" useRealService="false" id="b72651bd-93c8-43ab-a89a-32214a28853a" name=" Endpoint">
    <vs:virtualInputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:virtualOutputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:realInputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:realOutputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:properties>
      <entry key="HTTP.AuthenticationAutodetect">True</entry>
      <entry key="HTTP.Custom401UnauthorizedHandling">False</entry>
      <entry key="REST.StrictUriSpecification">False</entry>
    </vs:properties>
  </vs:virtualEndpoint>
  <vs:dataModel ref="4ced458e-f0ce-48c7-b4d7-698633eeebb4" />
  <vs:performanceModel ref="88c237c3-8904-4d34-b781-e7efb94635ea" />
  <vs:performanceModel ref="9529d72e-08fa-40d0-bb62-e930423bc6c8" />
  <vs:performanceModel ref="3cff1d89-6350-4ff6-b75d-a82744168c35" />
  <vs:configuration id="4303060e-f233-4c7a-a7b4-bddf4b6f355c" name="linux-stats Configuration">
    <vs:httpAuthentication>None</vs:httpAuthentication>
    <vs:httpAuthenticationAutodetect>True</vs:httpAuthenticationAutodetect>
    <vs:credentialStore id="2d46231b-2f73-4d2d-85b1-9eeb4c9c4882">
      <vs:credentials />
      <vs:identities />
    </vs:credentialStore>
    <vs:securityConfiguration>
      <credentials>
        <userName value="Identity[0].UsernamePassword" />
        <clientCertificate value="Identity[0].Certificate" />
        <serviceCertificate value="ServiceIdentity.Certificate" />
      </credentials>
      <security />
    </vs:securityConfiguration>
    <vs:messageSchemaLocked>False</vs:messageSchemaLocked>
    <vs:enableTrackLearning>True</vs:enableTrackLearning>
    <vs:logMessages>False</vs:logMessages>
  </vs:configuration>
</vs:virtualService>