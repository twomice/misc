/**
 * For a given date string and format, tell whether the date string is valid.
 *
 * @param string input_date A string to be parsed as a date or date/time
 * @param string format A foramt string, as per Pentaho date2str or str2date
 * @returns Boolean
 */
validate_date = function(input_date, format) {
 try {
  calc_date = date2str(str2date(input_date, format), format);

  if (calc_date.equals(input_date)) {
   return true;
  }
  else {
   return false;
  }
 }
 catch(e) {
  return false;
 }
}

normalizeSuffix = function(suffix) {
  if (suffix != null && typeof suffix != 'undefined') {
    return suffix
    .replace(/\./g, '')
    .trim()
  }
  else {
    return null;
  }
}

getRelationshipTypeId = function(reltype) {
  if (reltype != null && typeof reltype != 'undefined') {
    switch(String(reltype)) {
      case 'Other Relative':
        return 19;
        break;

      case 'Mother/Mother-In-Law':
      case 'Son/Son-In-Law':
      case 'Father/Father-In-Law':
      case 'Daughter/Daughter-In-Law':
      case 'Mother-in-Law':
        return 1;
        break;

      case 'wife':
      case 'Husband':
      case 'spouce':
      case 'Spouse':
        return 2;
        break;

      case 'Sibling':
        return 4;
        break;

      case 'Grandparent':
        return 20;
        break;

      case 'step daughter':
        return 21;
        break;

      case 'Non-Relative':
      case 'h':
      default:
        return -1;
        break;
    }
  }
  else {
    return null;
  }
}

getRelationshipTypeClientAOrB = function(reltype) {
  if (reltype != null && typeof reltype != 'undefined') {
    switch(String(reltype)) {

      case 'Mother/Mother-In-Law':
      case 'Father/Father-In-Law':
      case 'Mother-in-Law':
      case 'Grandparent':
        return 'a';
        break;

      case 'Son/Son-In-Law':
      case 'Daughter/Daughter-In-Law':
      case 'step daughter':
        return 'b';
        break;

      case 'Other Relative':
      case 'wife':
      case 'Husband':
      case 'spouce':
      case 'Spouse':
      case 'Sibling':
        // doesn't matter. just return 'a'.
        return 'a';
        break;

      default:
        // not found; return null;
        return null;
        break;
    }
  }
  else {
    return null;
  }
}


normalizePrefix = function(prefix) {
  if (prefix != null && typeof prefix != 'undefined') {
    return prefix
    .replace(/\s*and\s*.+$/i, '') // and
    .replace(/\s*\/\s*.+$/i, '')  // /
    .replace('7', '&')       //  &
    .replace(/\s*&.+$/, '')       //  &
    .replace(/\n.+$/i, '')
    .replace(/,/g, '.')
    .replace(/\./g, '')
    .replace(/^the\b/i, '')
    .replace(/^.$/, '')
    .replace(/^Nr$/, 'Mr')
    .replace(/^Nrs$/, 'Mrs')
    .replace(/^Mx$/, 'Ms')
    .replace(/^Father$/, 'Fr')
    .replace(/^Mstr$/, 'Master')
    .replace(/^Mr Mrs$/, 'Mr')
    .replace(/^Reverend$/, 'Rev')
    .replace(/^Monsingor$/, 'Msgr')
    .replace(/^Monsignor$/, 'Msgr')
    .replace(/^Mnsg$/, 'Msgr')
    .replace(/^Dcn$/, 'Deacon')
    .replace(/^Chao$/, 'Chaplain')
    .trim()
  }
  else {
    return null;
  }
}

padCiviCrmMultivalue = function(ar) {
  ar = ar.filter(function(e){return e});
  var delim = String.fromCharCode(1);
  if (ar.length) {
    return delim + ar.join(delim) + delim;
  }
  else {
    return null;
  }
}
