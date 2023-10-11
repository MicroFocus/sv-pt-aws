<?xml version="1.0" encoding="utf-8"?>
<vs:virtualService version="5.9.0.1616" id="d469b40b-f587-4334-9099-1d5073abf802" name="portfolio-suggestion-rest" description="No 8, 9, 10, 11 hands-on implemented;v230908" activeConfiguration="060e2c00-c686-4f3e-a768-90d79991999e" nonExistentRealService="false" lastModifier="Jakub" lastModification="63829756586784" xmlns:vs="http://hp.com/SOAQ/ServiceVirtualization/2010/">
  <vs:projectId ref="{2DF52534-4D25-4AA6-A1FC-C1DF635F5A9E}" />
  <vs:projectName>portfolio-suggestion-rest</vs:projectName>
  <vs:serviceDescription ref="66e4dfed-d2e7-40b3-9156-9c4a22f7802f" />
  <vs:virtualEndpoint type="HTTP" address="suggestportfolio" realAddress="https://localhost:7303/suggestportfolio" isTemporary="false" isDiscovered="false" useRealService="true" id="58fdabef-f6dd-43be-8086-5839e6594229" name=" Endpoint">
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
  <vs:dataModel ref="f0461b6e-8b09-40cc-92f4-7453cd7d091c" />
  <vs:performanceModel ref="e5afab3f-dac9-46a8-9126-19f936832394" />
  <vs:performanceModel ref="dd7009ce-fe13-42f8-851b-054d6427e1c0" />
  <vs:performanceModel ref="01210dc1-f48e-4b9f-a6b2-1ffd53a0f733" />
  <vs:customConditionPrototype condition="$data_int &lt;= $input_int AND $data_int &gt; $input_int -30" parentVirtualService="d469b40b-f587-4334-9099-1d5073abf802" id="e5625064-0ee6-4ca1-bb87-c58e9960aacf" name="Is Lower Then" />
  <vs:configuration id="060e2c00-c686-4f3e-a768-90d79991999e" name="Portfolio Suggestion Service Configuration">
    <vs:httpAuthentication>None</vs:httpAuthentication>
    <vs:httpAuthenticationAutodetect>True</vs:httpAuthenticationAutodetect>
    <vs:credentialStore id="3ab13267-ea05-4530-9e2a-a383a9fc0597">
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