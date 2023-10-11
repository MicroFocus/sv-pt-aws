<?xml version="1.0" encoding="utf-8"?>
<vs:virtualService version="5.9.0.1616" id="abce5250-415a-4826-b2bb-04e6138c4400" name="aws-cli" description="Virtual service using REST" activeConfiguration="a14f11e5-af41-4756-9a75-556795a2c990" nonExistentRealService="true" lastModifier="Jakub" lastModification="63828318758543" xmlns:vs="http://hp.com/SOAQ/ServiceVirtualization/2010/">
  <vs:projectId ref="{47A75FEA-F935-45D7-A893-990827B8544A}" />
  <vs:projectName>aws</vs:projectName>
  <vs:serviceDescription ref="f1825389-6653-4969-b341-a6d21aee0c8b" />
  <vs:virtualEndpoint type="HTTP" address="/aws-cli" realAddress="" isTemporary="false" isDiscovered="false" useRealService="false" id="12fc9957-fbe7-4480-8a11-054ac4a5ac61" name=" Endpoint">
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
  <vs:dataModel ref="40b6286f-4c29-46a5-a95b-4284fd2b9aff" />
  <vs:performanceModel ref="394b392d-4e78-45eb-b893-c66e7db9381e" />
  <vs:performanceModel ref="934eaf5f-8306-4ad6-bba0-e9bff1a0165f" />
  <vs:performanceModel ref="c7f79a4b-3db9-46bb-9235-b40893749be4" />
  <vs:configuration id="a14f11e5-af41-4756-9a75-556795a2c990" name="aws-cli Configuration">
    <vs:httpAuthentication>None</vs:httpAuthentication>
    <vs:httpAuthenticationAutodetect>True</vs:httpAuthenticationAutodetect>
    <vs:credentialStore id="aa94734a-9e02-4b76-bd51-e31607f2b500">
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