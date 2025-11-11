Represents additional information associated with a duplicate match record.

This class wraps `Datacloud.AdditionalInformationMap` and provides name-value pairs with supplemental matching data returned during duplicate detection.

## Properties

| Property Name | Data Type | Details                                                   |
| ------------- | --------- | --------------------------------------------------------- |
| name          | String    | The name of the additional information field. Read-only.  |
| value         | String    | The value of the additional information field. Read-only. |

## Methods

### `getName`

Returns the name of the additional information field.

- `String getName()`

```apex
Duplicates.AdditionalInformationMap info = matchRecord.getAdditionalInformation()?.get(0);
String name = info?.getName();
```

### `getValue`

Returns the value of the additional information field.

- `String getValue()`

```apex
Duplicates.AdditionalInformationMap info = matchRecord.getAdditionalInformation()?.get(0);
String value = info?.getValue();
```

### `toDatacloudType`

Returns the underlying native `Datacloud.AdditionalInformationMap` instance.

- `Datacloud.AdditionalInformationMap toDatacloudType()`

```apex
Datacloud.AdditionalInformationMap nativeInfo = info?.toDatacloudType();
```
