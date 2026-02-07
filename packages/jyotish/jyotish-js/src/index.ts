/**
 * Jyotish JS - A JavaScript/TypeScript library for Vedic astrology calculations
 *
 * This library provides comprehensive tools for Vedic astrology including:
 * - Ashtakoot Gun Milan (36-point compatibility matching)
 * - Detailed compatibility analysis
 * - Support for moon sign and nakshatra calculations
 *
 * @packageDocumentation
 */

// Models
export { MatchingPerson } from "./models/MatchingPerson.js";
export { GunScore } from "./models/GunScore.js";
export { AshtakootResult } from "./models/AshtakootResult.js";
export {
  CompatibilityLevel,
  CompatibilityLevelInfo,
  getCompatibilityLevel,
} from "./models/CompatibilityLevel.js";

// Services
export { AshtakootService } from "./services/AshtakootService.js";

// Constants
export { VarnaConstants } from "./constants/VarnaConstants.js";
export { VasyaConstants } from "./constants/VasyaConstants.js";
export { TaraConstants } from "./constants/TaraConstants.js";
export { YoniConstants } from "./constants/YoniConstants.js";
export { GrahaMaitriConstants } from "./constants/GrahaMaitriConstants.js";
export { GanaConstants } from "./constants/GanaConstants.js";
export { BhakootConstants } from "./constants/BhakootConstants.js";
export { NadiConstants } from "./constants/NadiConstants.js";
