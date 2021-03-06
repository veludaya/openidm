SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING,ANSI_WARNINGS,CONCAT_NULL_YIELDS_NULL,ARITHABORT,QUOTED_IDENTIFIER,ANSI_NULLS ON
GO

IF (NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE (name = N'openidm')))
-- -----------------------------------------------------
-- Database OpenIDM - case-sensitive and accent-sensitive
-- -----------------------------------------------------
CREATE DATABASE [openidm] COLLATE Latin1_General_100_CS_AS
GO
ALTER DATABASE [openidm] SET READ_COMMITTED_SNAPSHOT ON
GO
USE [openidm]
GO

-- -----------------------------------------------------
-- Login openidm
-- -----------------------------------------------------
IF (NOT EXISTS (select loginname from master.dbo.syslogins where name = N'openidm' and dbname = N'openidm'))
CREATE LOGIN [openidm] WITH PASSWORD=N'openidm', DEFAULT_DATABASE=[openidm], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

-- -----------------------------------------------------
-- User openidm - Database owner user
-- -----------------------------------------------------
IF (NOT EXISTS (select name from dbo.sysusers where name = N'openidm'))
CREATE USER [openidm]		  FOR LOGIN [openidm] WITH DEFAULT_SCHEMA = [openidm]
GO

-- -----------------------------------------------------
-- Schema openidm
-- -----------------------------------------------------
IF (NOT EXISTS (SELECT name FROM sys.schemas WHERE name = N'openidm'))
EXECUTE sp_executesql N'CREATE SCHEMA [openidm] AUTHORIZATION [openidm]'

EXEC sp_addrolemember N'db_owner', N'openidm'
GO

BEGIN TRANSACTION

-- -----------------------------------------------------
-- Table `openidm`.`objecttypes`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='objecttypes' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[objecttypes]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttype NVARCHAR(255) NOT NULL ,
  PRIMARY KEY CLUSTERED (id) ,
);
CREATE UNIQUE INDEX idx_objecttypes_objecttype ON [openidm].[objecttypes] (objecttype ASC);
END

-- -----------------------------------------------------
-- Table `openidm`.`genericobjects`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='genericobjects' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[genericobjects]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttypes_id NUMERIC(19,0) NOT NULL ,
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  fullobject NTEXT NULL ,

  CONSTRAINT fk_genericobjects_objecttypes
  	FOREIGN KEY (objecttypes_id)
  	REFERENCES [openidm].[objecttypes] (id)
  	ON DELETE CASCADE
  	ON UPDATE NO ACTION,
  PRIMARY KEY CLUSTERED (id),
);
CREATE UNIQUE INDEX idx_genericobjects_object ON [openidm].[genericobjects] (objecttypes_id ASC, objectid ASC);
CREATE INDEX fk_genericobjects_objecttypes ON [openidm].[genericobjects] (objecttypes_id ASC);
END

-- -----------------------------------------------------
-- Table `openidm`.`genericobjectproperties`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='genericobjectproperties' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[genericobjectproperties]
(
  genericobjects_id NUMERIC(19,0) NOT NULL ,
  propkey NVARCHAR(255) NOT NULL ,
  proptype NVARCHAR(32) NULL ,
  propvalue NVARCHAR(195) NULL ,
  CONSTRAINT fk_genericobjectproperties_genericobjects
    FOREIGN KEY (genericobjects_id)
    REFERENCES [openidm].[genericobjects] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
CREATE INDEX fk_genericobjectproperties_genericobjects ON [openidm].[genericobjectproperties] (genericobjects_id ASC);
CREATE INDEX idx_genericobjectproperties_propkey ON [openidm].[genericobjectproperties] (propkey ASC);
CREATE INDEX idx_genericobjectproperties_propvalue ON [openidm].[genericobjectproperties] (propvalue ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`managedobjects`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='managedobjects' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[managedobjects]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttypes_id NUMERIC(19,0) NOT NULL ,
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  fullobject NTEXT NULL ,
  CONSTRAINT fk_managedobjects_objectypes
    FOREIGN KEY (objecttypes_id)
    REFERENCES [openidm].[objecttypes] (id )
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  PRIMARY KEY CLUSTERED (id),
);
CREATE UNIQUE INDEX idx_managedobjects_object ON [openidm].[managedobjects] (objecttypes_id ASC, objectid ASC);
CREATE INDEX fk_managedobjects_objectypes ON [openidm].[managedobjects] (objecttypes_id ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`managedobjectproperties`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='managedobjectproperties' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[managedobjectproperties]
(
  managedobjects_id NUMERIC(19,0) NOT NULL ,
  propkey NVARCHAR(255) NOT NULL ,
  proptype NVARCHAR(32) NULL ,
  propvalue NVARCHAR(195) NULL ,
  CONSTRAINT fk_managedobjectproperties_managedobjects
    FOREIGN KEY (managedobjects_id)
    REFERENCES [openidm].[managedobjects] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
CREATE INDEX fk_managedobjectproperties_managedobjects ON [openidm].[managedobjectproperties] (managedobjects_id ASC);
CREATE INDEX idx_managedobjectproperties_propkey ON [openidm].[managedobjectproperties] (propkey ASC);
CREATE INDEX idx_managedobjectproperties_propvalue ON [openidm].[managedobjectproperties] (propvalue ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`configobjects`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='configobjects' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[configobjects]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttypes_id NUMERIC(19,0) NOT NULL ,
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  fullobject NTEXT NULL ,
  CONSTRAINT fk_configobjects_objecttypes
    FOREIGN KEY (objecttypes_id)
    REFERENCES [openidm].[objecttypes] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  PRIMARY KEY CLUSTERED (id),
);
CREATE INDEX fk_configobjects_objecttypes ON [openidm].[configobjects] (objecttypes_id ASC);
CREATE UNIQUE INDEX idx_configobjects_object ON [openidm].[configobjects] (objecttypes_id ASC, objectid ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`configobjectproperties`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='configobjectproperties' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[configobjectproperties] (
  configobjects_id NUMERIC(19,0) NOT NULL ,
  propkey NVARCHAR(255) NOT NULL ,
  proptype NVARCHAR(255) NULL ,
  propvalue NVARCHAR(195) NULL ,
  CONSTRAINT fk_configobjectproperties_configobjects
    FOREIGN KEY (configobjects_id)
    REFERENCES [openidm].[configobjects] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
CREATE INDEX fk_configobjectproperties_configobjects ON [openidm].[configobjectproperties] (configobjects_id ASC);
CREATE INDEX idx_configobjectproperties_propkey ON [openidm].[configobjectproperties] (propkey ASC);
CREATE INDEX idx_configobjectproperties_propvalue ON [openidm].[configobjectproperties] (propvalue ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`relationships`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='relationships' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[relationships]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttypes_id NUMERIC(19,0) NOT NULL ,
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  fullobject NTEXT NULL ,
  CONSTRAINT fk_relationships_objecttypes
    FOREIGN KEY (objecttypes_id)
    REFERENCES [openidm].[objecttypes] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  PRIMARY KEY CLUSTERED (id),
);
CREATE INDEX fk_relationships_objecttypes ON [openidm].[relationships] (objecttypes_id ASC);
CREATE UNIQUE INDEX idx_relationships_object ON [openidm].[relationships] (objecttypes_id ASC, objectid ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`relationshipproperties`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='relationshipproperties' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[relationshipproperties] (
  relationships_id NUMERIC(19,0) NOT NULL ,
  propkey NVARCHAR(255) NOT NULL ,
  proptype NVARCHAR(255) NULL ,
  propvalue NVARCHAR(195) NULL ,
  CONSTRAINT fk_relationshipproperties_relationships
    FOREIGN KEY (relationships_id)
    REFERENCES [openidm].[relationships] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
CREATE INDEX fk_relationshipproperties_relationships ON [openidm].[relationshipproperties] (relationships_id ASC);
CREATE INDEX idx_relationshipproperties_propkey ON [openidm].[relationshipproperties] (propkey ASC);
CREATE INDEX idx_relationshipproperties_propvalue ON [openidm].[relationshipproperties] (propvalue ASC);
END

-- -----------------------------------------------------
-- Table `openidm`.`links`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='links' AND xtype='U')
BEGIN
CREATE  TABLE  [openidm].[links]
(
  objectid NVARCHAR(38) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  linktype NVARCHAR(50) NOT NULL ,
  linkqualifier NVARCHAR(50) NOT NULL ,
  firstid NVARCHAR(255) NOT NULL ,
  secondid NVARCHAR(255) NOT NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
CREATE UNIQUE INDEX idx_links_first ON [openidm].[links] (linktype ASC, linkqualifier ASC, firstid ASC);
CREATE UNIQUE INDEX idx_links_second ON [openidm].[links] (linktype ASC, linkqualifier ASC, secondid ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`securitykeys`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='securitykeys' AND xtype='U')
BEGIN
CREATE  TABLE  [openidm].[securitykeys]
(
  objectid NVARCHAR(38) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  keypair NTEXT NOT NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
END


-- -----------------------------------------------------
-- Table `openidm`.`auditrecon`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='auditrecon' AND xtype='U')
BEGIN
CREATE  TABLE  [openidm].[auditrecon]
(
  objectid NVARCHAR(56) NOT NULL ,
  transactionid NVARCHAR(255) NOT NULL ,
  activitydate NVARCHAR(29) NOT NULL ,
  eventname NVARCHAR(50) NULL ,
  userid NVARCHAR(255) NULL ,
  trackingids NTEXT ,
  activity NVARCHAR(24) NULL ,
  exceptiondetail NTEXT NULL ,
  linkqualifier NVARCHAR(255) NULL ,
  mapping NVARCHAR(511) NULL ,
  message NTEXT NULL ,
  messagedetail NTEXT NULL ,
  situation NVARCHAR(24) NULL ,
  sourceobjectid NVARCHAR(511) NULL ,
  status NVARCHAR(20) NULL ,
  targetobjectid NVARCHAR(511) NULL ,
  reconciling NVARCHAR(12) NULL ,
  ambiguoustargetobjectids NTEXT NULL ,
  reconaction NVARCHAR(36) NULL ,
  entrytype NVARCHAR(7) NULL ,
  reconid NVARCHAR(56) NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
EXEC sp_addextendedproperty 'MS_Description', 'Date format: 2011-09-09T14:58:17.654+02:00', 'SCHEMA', openidm, 'TABLE', auditrecon, 'COLUMN', activitydate;
END


-- -----------------------------------------------------
-- Table `openidm`.`auditsync`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='auditsync' AND xtype='U')
BEGIN
CREATE  TABLE  [openidm].[auditsync]
(
  objectid NVARCHAR(56) NOT NULL ,
  transactionid NVARCHAR(255) NOT NULL ,
  activitydate NVARCHAR(29) NOT NULL ,
  eventname NVARCHAR(50) NULL ,
  userid NVARCHAR(255) NULL ,
  trackingids NTEXT ,
  activity NVARCHAR(24) NULL ,
  exceptiondetail NTEXT NULL ,
  linkqualifier NVARCHAR(255) NULL ,
  mapping NVARCHAR(511) NULL ,
  message NTEXT NULL ,
  messagedetail NTEXT NULL ,
  situation NVARCHAR(24) NULL ,
  sourceobjectid NVARCHAR(511) NULL ,
  status NVARCHAR(20) NULL ,
  targetobjectid NVARCHAR(511) NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
EXEC sp_addextendedproperty 'MS_Description', 'Date format: 2011-09-09T14:58:17.654+02:00', 'SCHEMA', openidm, 'TABLE', auditsync, 'COLUMN', activitydate;
END

-- -----------------------------------------------------
-- Table `openidm`.`auditconfig`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='auditconfig' and xtype='U')
  BEGIN
    CREATE  TABLE [openidm].[auditconfig]
    (
      objectid NVARCHAR(56) NOT NULL,
      activitydate NVARCHAR(29) NOT NULL,
      eventname NVARCHAR(255) NULL,
      transactionid NVARCHAR(255) NOT NULL,
      userid NVARCHAR(255) NULL,
      trackingids NTEXT,
      runas NVARCHAR(255) NULL,
      configobjectid NVARCHAR(255) NULL ,
      operation NVARCHAR(255) NULL ,
      beforeObject NTEXT,
      afterObject NTEXT,
      changedfields NTEXT NULL,
      rev NVARCHAR(255) NULL,
      PRIMARY KEY CLUSTERED (objectid),
    );
    CREATE INDEX idx_auditconfig_transactionid ON [openidm].[auditconfig] (transactionid ASC);
    EXEC sp_addextendedproperty 'MS_Description', 'Date format: 2011-09-09T14:58:17.654+02:00', 'SCHEMA', openidm, 'TABLE', auditconfig, 'COLUMN', activitydate;
  END


-- -----------------------------------------------------
-- Table `openidm`.`auditactivity`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='auditactivity' and xtype='U')
BEGIN
CREATE  TABLE [openidm].[auditactivity]
(
  objectid NVARCHAR(56) NOT NULL,
  activitydate NVARCHAR(29) NOT NULL,
  eventname NVARCHAR(255) NULL,
  transactionid NVARCHAR(255) NOT NULL,
  userid NVARCHAR(255) NULL,
  trackingids NTEXT,
  runas NVARCHAR(255) NULL,
  activityobjectid NVARCHAR(255) NULL ,
  operation NVARCHAR(255) NULL ,
  subjectbefore NTEXT,
  subjectafter NTEXT,
  changedfields NTEXT NULL,
  subjectrev NVARCHAR(255) NULL,
  passwordchanged NVARCHAR(5) NULL,
  message NTEXT,
  status NVARCHAR(20),
  PRIMARY KEY CLUSTERED (objectid),
);
CREATE INDEX idx_auditactivity_transactionid ON [openidm].[auditactivity] (transactionid ASC);
EXEC sp_addextendedproperty 'MS_Description', 'Date format: 2011-09-09T14:58:17.654+02:00', 'SCHEMA', openidm, 'TABLE', auditactivity, 'COLUMN', activitydate;
END

-- -----------------------------------------------------
-- Table `openidm`.`auditaccess`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='auditaccess' and xtype='U')
BEGIN
CREATE  TABLE [openidm].[auditaccess] (
  objectid NVARCHAR(56) NOT NULL ,
  activitydate NVARCHAR(29) NOT NULL ,
  eventname NVARCHAR(255) NULL ,
  transactionid NVARCHAR(255) NOT NULL ,
  userid NVARCHAR(255) NULL,
  trackingids NTEXT,
  server_ip NVARCHAR(40) ,
  server_port NVARCHAR(5) ,
  client_ip NVARCHAR(40) ,
  client_port NVARCHAR(5) ,
  request_protocol NVARCHAR(255) NULL ,
  request_operation NVARCHAR(255) NULL ,
  request_detail NTEXT NULL ,
  http_request_secure NVARCHAR(255) NULL ,
  http_request_method NVARCHAR(255) NULL ,
  http_request_path NVARCHAR(255) NULL ,
  http_request_queryparameters NTEXT NULL ,
  http_request_headers NTEXT NULL ,
  http_request_cookies NTEXT NULL ,
  http_response_headers NTEXT NULL ,
  response_status NVARCHAR(255) NULL ,
  response_statuscode NVARCHAR(255) NULL ,
  response_elapsedtime NVARCHAR(255) NULL ,
  response_elapsedtimeunits NVARCHAR(255) NULL ,
  response_detail NTEXT NULL ,
  roles NTEXT NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
EXEC sp_addextendedproperty 'MS_Description', 'Date format: 2011-09-09T14:58:17.654+02:00', 'SCHEMA', openidm, 'TABLE', auditaccess, 'COLUMN', activitydate;
END

-- -----------------------------------------------------
-- Table openidm.auditauthentication
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='auditauthentication' and xtype='U')
BEGIN
CREATE TABLE [openidm].[auditauthentication] (
  objectid NVARCHAR(56) NOT NULL ,
  transactionid NVARCHAR(255) NOT NULL ,
  activitydate NVARCHAR(29) NOT NULL ,
  userid NVARCHAR(255) NULL ,
  eventname NVARCHAR(50) NULL ,
  result NVARCHAR(255) NULL ,
  principals NTEXT NULL ,
  context NTEXT NULL ,
  entries NTEXT NULL ,
  trackingids NTEXT,
  PRIMARY KEY CLUSTERED (objectid)
);
EXEC sp_addextendedproperty 'MS_Description', 'Date format: 2011-09-09T14:58:17.654+02:00', 'SCHEMA', openidm, 'TABLE', auditauthentication, 'COLUMN', activitydate;
END

-- -----------------------------------------------------
-- Table `openidm`.`internaluser`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='internaluser' and xtype='U')
BEGIN
CREATE  TABLE [openidm].[internaluser]
(
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  pwd NVARCHAR(510) NULL ,
  roles NVARCHAR(1024) NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
END


-- -----------------------------------------------------
-- Table `openidm`.`internalrole`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='internalrole' and xtype='U')
BEGIN
CREATE  TABLE [openidm].[internalrole]
(
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  description NVARCHAR(510) NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
END

-- -----------------------------------------------------
-- Table `openidm`.`schedulerobjects`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='schedulerobjects' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[schedulerobjects]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttypes_id NUMERIC(19,0) NOT NULL ,
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  fullobject NTEXT NULL ,
  CONSTRAINT fk_schedulerobjects_objecttypes
    FOREIGN KEY (objecttypes_id)
    REFERENCES [openidm].[objecttypes] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  PRIMARY KEY CLUSTERED (id),
);
CREATE INDEX fk_schedulerobjects_objecttypes ON [openidm].[schedulerobjects] (objecttypes_id ASC);
CREATE UNIQUE INDEX idx_schedulerobjects_object ON [openidm].[schedulerobjects] (objecttypes_id ASC, objectid ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`schedulerobjectproperties`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='schedulerobjectproperties' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[schedulerobjectproperties] (
  schedulerobjects_id NUMERIC(19,0) NOT NULL ,
  propkey NVARCHAR(255) NOT NULL ,
  proptype NVARCHAR(32) NULL ,
  propvalue NVARCHAR(195) NULL ,
  CONSTRAINT fk_schedulerobjectproperties_schedulerobjects
    FOREIGN KEY (schedulerobjects_id)
    REFERENCES [openidm].[schedulerobjects] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
CREATE INDEX fk_schedulerobjectproperties_schedulerobjects ON [openidm].[schedulerobjectproperties] (schedulerobjects_id ASC);
CREATE INDEX idx_schedulerobjectproperties_propkey ON [openidm].[schedulerobjectproperties] (propkey ASC);
CREATE INDEX idx_schedulerobjectproperties_propvalue ON [openidm].[schedulerobjectproperties] (propvalue ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`clusterobjects`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='clusterobjects' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[clusterobjects]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttypes_id NUMERIC(19,0) NOT NULL ,
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  fullobject NTEXT NULL ,
  CONSTRAINT fk_clusterobjects_objecttypes
    FOREIGN KEY (objecttypes_id)
    REFERENCES [openidm].[objecttypes] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  PRIMARY KEY CLUSTERED (id),
);
CREATE INDEX fk_clusterobjects_objecttypes ON [openidm].[clusterobjects] (objecttypes_id ASC);
CREATE UNIQUE INDEX idx_clusterobjects_object ON [openidm].[clusterobjects] (objecttypes_id ASC, objectid ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`clusterobjectproperties`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='clusterobjectproperties' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[clusterobjectproperties] (
  clusterobjects_id NUMERIC(19,0) NOT NULL ,
  propkey NVARCHAR(255) NOT NULL ,
  proptype NVARCHAR(32) NULL ,
  propvalue NVARCHAR(195) NULL ,
  CONSTRAINT fk_clusterobjectproperties_clusterobjects
    FOREIGN KEY (clusterobjects_id)
    REFERENCES [openidm].[clusterobjects] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
CREATE INDEX fk_clusterobjectproperties_clusterobjects ON [openidm].[clusterobjectproperties] (clusterobjects_id ASC);
CREATE INDEX idx_clusterobjectproperties_propkey ON [openidm].[clusterobjectproperties] (propkey ASC);
CREATE INDEX idx_clusterobjectproperties_propvalue ON [openidm].[clusterobjectproperties] (propvalue ASC);
END


-- -----------------------------------------------------
-- Table `openidm`.`uinotification`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='uinotification' and xtype='U')
BEGIN
CREATE  TABLE [openidm].[uinotification] (
  objectid NVARCHAR(38) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  notificationtype NVARCHAR(255) NOT NULL ,
  createdate NVARCHAR(255) NOT NULL ,
  message NTEXT NOT NULL ,
  requester NVARCHAR(255) NULL ,
  receiverid NVARCHAR(38) NOT NULL ,
  requesterid NVARCHAR(38) NULL ,
  notificationsubtype NVARCHAR(255) NULL ,
  PRIMARY KEY CLUSTERED (objectid)
);
EXEC sp_addextendedproperty 'MS_Description', 'Date format: 2011-09-09T14:58:17.654+02:00', 'SCHEMA', openidm, 'TABLE', uinotification, 'COLUMN', createdate;
END


-- -----------------------------------------------------
-- Table `openidm`.`updateobjects`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='updateobjects' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[updateobjects]
(
  id NUMERIC(19,0) NOT NULL IDENTITY ,
  objecttypes_id NUMERIC(19,0) NOT NULL ,
  objectid NVARCHAR(255) NOT NULL ,
  rev NVARCHAR(38) NOT NULL ,
  fullobject NTEXT NULL ,

  CONSTRAINT fk_updateobjects_objecttypes
  	FOREIGN KEY (objecttypes_id)
  	REFERENCES [openidm].[objecttypes] (id)
  	ON DELETE CASCADE
  	ON UPDATE NO ACTION,
  PRIMARY KEY CLUSTERED (id),
);
CREATE UNIQUE INDEX idx_updateobjects_object ON [openidm].[updateobjects] (objecttypes_id ASC, objectid ASC);
CREATE INDEX fk_updateobjects_objecttypes ON [openidm].[updateobjects] (objecttypes_id ASC);
END

-- -----------------------------------------------------
-- Table `openidm`.`updateobjectproperties`
-- -----------------------------------------------------
IF NOT EXISTS (SELECT name FROM sysobjects where name='updateobjectproperties' AND xtype='U')
BEGIN
CREATE  TABLE [openidm].[updateobjectproperties]
(
  updateobjects_id NUMERIC(19,0) NOT NULL ,
  propkey NVARCHAR(255) NOT NULL ,
  proptype NVARCHAR(32) NULL ,
  propvalue NVARCHAR(195) NULL ,
  CONSTRAINT fk_updateobjectproperties_updateobjects
    FOREIGN KEY (updateobjects_id)
    REFERENCES [openidm].[updateobjects] (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);
CREATE INDEX fk_updateobjectproperties_updateobjects ON [openidm].[updateobjectproperties] (updateobjects_id ASC);
CREATE INDEX idx_updateobjectproperties_propkey ON [openidm].[updateobjectproperties] (propkey ASC);
CREATE INDEX idx_updateobjectproperties_propvalue ON [openidm].[updateobjectproperties] (propvalue ASC);
END


-- -----------------------------------------------------
-- Data for table `openidm`.`internaluser`
-- -----------------------------------------------------
IF (NOT EXISTS (SELECT objectid FROM openidm.internaluser WHERE objectid = N'openidm-admin'))
INSERT INTO [openidm].[internaluser] (objectid, rev, pwd, roles) VALUES (N'openidm-admin', '0', 'openidm-admin', '[ { "_ref" : "repo/internal/role/openidm-admin" }, { "_ref" : "repo/internal/role/openidm-authorized" } ]');

IF (NOT EXISTS (SELECT objectid FROM openidm.internaluser WHERE objectid = N'anonymous'))
INSERT INTO [openidm].[internaluser] (objectid, rev, pwd, roles) VALUES ('anonymous', '0', 'anonymous', '[ { "_ref" : "repo/internal/role/openidm-reg" } ]');

INSERT INTO openidm.internalrole (objectid, rev, description)
VALUES
('openidm-authorized', '0', 'Basic minimum user'),
('openidm-admin', '0', 'Administrative access'),
('openidm-cert', '0', 'Authenticated via certificate'),
('openidm-tasks-manager', '0', 'Allowed to reassign workflow tasks'),
('openidm-reg', '0', 'Anonymous access');

COMMIT
GO
USE [master]
GO
