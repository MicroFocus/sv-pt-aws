<?xml version="1.0" encoding="utf-8"?>
<vs:virtualService version="5.9.0.1616" id="145059a3-78a4-47df-a467-7a4f8291db64" name="member-accounts-soap" description="v20231002" activeConfiguration="10c2323c-8037-4496-acbe-18333939be8d" nonExistentRealService="false" lastModifier="Jakub" lastModification="63831835636120" xmlns:vs="http://hp.com/SOAQ/ServiceVirtualization/2010/">
  <vs:projectId ref="{A71B533D-D7E4-4656-A913-78450CF3CDD9}" />
  <vs:projectName>member-accounts-soap</vs:projectName>
  <vs:serviceDescription ref="1549e34f-8779-4e12-82c6-fe0701595785" />
  <vs:virtualEndpoint type="HTTP" address="demo/SOAP/MemberAccounts" realAddress="http://vondraknb4:8101/demo/SOAP/MemberAccounts" isTemporary="false" isDiscovered="false" useRealService="true" id="a1c1eccf-609c-490f-b2fd-fd56f5b5fa38" name=" Endpoint">
    <vs:virtualInputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:virtualOutputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:realInputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:realOutputAgent ref="HttpAgent" name="HTTP Gateway" />
    <vs:properties />
  </vs:virtualEndpoint>
  <vs:dataModel ref="7697cb2a-14e6-4fae-994b-0bf09adbaa25" />
  <vs:performanceModel ref="f5863dec-f4bc-47df-ae37-ab4ea8469aa0" />
  <vs:performanceModel ref="4960e875-0f4a-4e0d-9c11-42f56dc83de4" />
  <vs:performanceModel ref="04353dab-829b-4905-b122-5d8d106b498a" />
  <vs:performanceModel ref="406f14f4-c921-4237-8b38-e813f9809db1" />
  <vs:configuration id="10c2323c-8037-4496-acbe-18333939be8d" name="MemberAccounts Configuration">
    <vs:httpAuthentication>None</vs:httpAuthentication>
    <vs:httpAuthenticationAutodetect>True</vs:httpAuthenticationAutodetect>
    <vs:credentialStore id="110960e4-41d5-4e90-a4c0-1c0e42e33b66">
      <vs:credentials>
        <vs:userNamePassword credentialName="UsernamePasswordCredential 1" userName="hpguest" password="hpguest" />
      </vs:credentials>
      <vs:identities>
        <vs:identity identityId="hpguest" usage="service">
          <vs:linkedCredential logicalId="UsernamePassword" credentialName="UsernamePasswordCredential 1" />
        </vs:identity>
      </vs:identities>
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