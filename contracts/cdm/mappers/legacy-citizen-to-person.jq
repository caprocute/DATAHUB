# Mapper JQ: HTTT giả (citizen) → CDM person.v1 (WP-22 / ADR-013)
{
  personId: (.maCongDan // .citizenId // .id | tostring),
  fullName: (.hoTen // .fullName // ""),
  dateOfBirth: (.ngaySinh // .dob // null),
  nationalId: (.soCMND // .nationalId // null)
}
