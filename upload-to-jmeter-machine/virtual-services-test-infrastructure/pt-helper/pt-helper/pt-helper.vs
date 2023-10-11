<?xml version="1.0" encoding="utf-8"?>
<vs:virtualService version="5.9.0.1616" id="9baf3683-1b6a-437b-bbfd-c617235a0712" name="pt-helper" description="Virtual service using REST" activeConfiguration="73e27016-d558-4a23-8da8-bdda0b81452b" nonExistentRealService="true" lastModifier="Jakub" lastModification="63831833568139" xmlns:vs="http://hp.com/SOAQ/ServiceVirtualization/2010/">
  <vs:projectId ref="{617F3E80-5BD9-47D5-80B3-823882D02887}" />
  <vs:projectName>pt-helper</vs:projectName>
  <vs:serviceDescription ref="2bed11c0-2134-4e1d-ae7b-722e14ab9e46" />
  <vs:virtualEndpoint type="HTTP" address="/pt-helper" realAddress="" isTemporary="false" isDiscovered="false" useRealService="false" id="2116f0b5-8830-47e0-a996-7607f817fbb3" name=" Endpoint">
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
  <vs:dataModel ref="8e11b25d-6f09-4e6b-a0fa-afdcf8720341" />
  <vs:performanceModel ref="e934f71c-6d14-4bee-b7d4-51234be662ab" />
  <vs:performanceModel ref="308feada-38c7-451f-b978-ab955a1dc7bf" />
  <vs:performanceModel ref="dcb2efbf-6ce6-4a6d-a574-760e52b74f51" />
  <vs:configuration id="73e27016-d558-4a23-8da8-bdda0b81452b" name="pt-helper Configuration">
    <vs:httpAuthentication>None</vs:httpAuthentication>
    <vs:httpAuthenticationAutodetect>True</vs:httpAuthenticationAutodetect>
    <vs:credentialStore id="ec88ca8a-8b1a-430d-8a38-20ffed584b6c">
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