<?xml version="1.0" encoding="utf-8"?>
<vs:virtualService version="5.9.0.1616" id="812f5c26-9a7b-46e7-840a-bcd1285f4c10" name="member-accounts-binary" description="v20230908" activeConfiguration="bd56322a-863d-4afb-880b-eeca66e6ae00" nonExistentRealService="false" lastModifier="Jakub" lastModification="63829756700152" xmlns:vs="http://hp.com/SOAQ/ServiceVirtualization/2010/">
  <vs:projectId ref="{57CE8A06-92F7-4A67-B0B4-1F6A55739FF5}" />
  <vs:projectName>member-accounts-binary</vs:projectName>
  <vs:serviceDescription ref="5c3ecd89-b0af-4907-ba24-ef129ce26446" />
  <vs:virtualEndpoint type="HTTP" address="demo/binary/MemberAccounts" realAddress="http://localhost:8101/demo/SOAP/MemberAccounts" isTemporary="false" isDiscovered="false" useRealService="true" id="b03a36c1-2d73-4dc3-bddb-479076640a12" name=" Endpoint">
    <vs:virtualInputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:virtualOutputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:realInputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:realOutputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:properties />
  </vs:virtualEndpoint>
  <vs:dataModel ref="0472d37e-2291-4493-a426-a1f65c274761" />
  <vs:performanceModel ref="8d3765be-888b-4a42-a01a-793a99617980" />
  <vs:performanceModel ref="c3a6fcf6-a6ce-4222-9cb7-02c7985cf7f8" />
  <vs:performanceModel ref="99512317-eb9b-4b6f-a835-108be7d01e3d" />
  <vs:configuration id="bd56322a-863d-4afb-880b-eeca66e6ae00" name="member-accounts-binary Configuration">
    <vs:httpAuthentication>None</vs:httpAuthentication>
    <vs:httpAuthenticationAutodetect>True</vs:httpAuthenticationAutodetect>
    <vs:credentialStore id="b296e3a1-23bc-4c4a-836e-0997fb895113">
      <vs:credentials />
      <vs:identities />
    </vs:credentialStore>
    <vs:securityConfiguration>
      <security />
      <clientSecurity />
      <serviceSecurity />
      <credentials>
        <clientCertificate value="Identity[0].Certificate" />
        <serviceCertificate value="ServiceIdentity.Certificate" />
        <userName value="Identity[0].UsernamePassword" />
      </credentials>
    </vs:securityConfiguration>
    <vs:messageSchemaLocked>False</vs:messageSchemaLocked>
    <vs:enableTrackLearning>True</vs:enableTrackLearning>
    <vs:logMessages>False</vs:logMessages>
  </vs:configuration>
</vs:virtualService>