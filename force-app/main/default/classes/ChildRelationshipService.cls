@SuppressWarnings('PMD.ApexDoc')
public abstract class ChildRelationshipService {
	// ! Deprecated: This class & all its methods will be removed in future versions
	// ! Replace all uses of this class with DatabaseLayer.Utils methods w/the same name
	public static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
		return DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(lookupField, referenceTo);
	}

	public static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
		return DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(lookupField);
	}
}
