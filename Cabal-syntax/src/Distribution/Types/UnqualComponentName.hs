{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Distribution.Types.UnqualComponentName
  ( UnqualComponentName
  , unUnqualComponentName
  , unUnqualComponentNameST
  , mkUnqualComponentName
  , packageNameToUnqualComponentName
  , unqualComponentNameToPackageName
  , combineNames
  ) where

import Distribution.Compat.Prelude
import Distribution.Utils.ShortText
import Prelude as P (null)

import Distribution.Parsec
import Distribution.Pretty
import Distribution.Types.PackageName

-- | An unqualified component name, for any kind of component.
--
-- This is distinguished from a 'ComponentName' and 'ComponentId'. The former
-- also states which of a library, executable, etc the name refers too. The
-- later uniquely identifiers a component and its closure.
--
-- @since 2.0.0.2
newtype UnqualComponentName = UnqualComponentName ShortText
  deriving
    ( Generic
    , Read
    , Show
    , Eq
    , Ord
    , Typeable
    , Data
    , Semigroup
    , Monoid -- TODO: bad enabler of bad monoids
    )

-- | Convert 'UnqualComponentName' to 'String'
--
-- @since 2.0.0.2
unUnqualComponentName :: UnqualComponentName -> String
unUnqualComponentName (UnqualComponentName s) = fromShortText s

-- | @since 3.4.0.0
unUnqualComponentNameST :: UnqualComponentName -> ShortText
unUnqualComponentNameST (UnqualComponentName s) = s

-- | Construct a 'UnqualComponentName' from a 'String'
--
-- 'mkUnqualComponentName' is the inverse to 'unUnqualComponentName'
--
-- Note: No validations are performed to ensure that the resulting
-- 'UnqualComponentName' is valid
--
-- @since 2.0.0.2
mkUnqualComponentName :: String -> UnqualComponentName
mkUnqualComponentName = UnqualComponentName . toShortText

-- | 'mkUnqualComponentName'
--
-- @since 2.0.0.2
instance IsString UnqualComponentName where
  fromString = mkUnqualComponentName

instance Binary UnqualComponentName
instance Structured UnqualComponentName

instance Pretty UnqualComponentName where
  pretty = showToken . unUnqualComponentName

instance Parsec UnqualComponentName where
  parsec = mkUnqualComponentName <$> parsecUnqualComponentName

instance NFData UnqualComponentName where
  rnf (UnqualComponentName pkg) = rnf pkg

-- TODO avoid String round trip with these PackageName <->
-- UnqualComponentName converters.

-- | Converts a package name to an unqualified component name
--
-- Useful in legacy situations where a package name may refer to an internal
-- component, if one is defined with that name.
--
-- 2018-12-21: These "legacy" situations are not legacy.
-- We can @build-depends@ on the internal library. However
-- Now dependency contains @Set LibraryName@, and we should use that.
--
-- @since 2.0.0.2
packageNameToUnqualComponentName :: PackageName -> UnqualComponentName
packageNameToUnqualComponentName = UnqualComponentName . unPackageNameST

-- | Converts an unqualified component name to a package name
--
-- `packageNameToUnqualComponentName` is the inverse of
-- `unqualComponentNameToPackageName`.
--
-- Useful in legacy situations where a package name may refer to an internal
-- component, if one is defined with that name.
--
-- @since 2.0.0.2
unqualComponentNameToPackageName :: UnqualComponentName -> PackageName
unqualComponentNameToPackageName = mkPackageNameST . unUnqualComponentNameST

-- | Combine names in targets if one name is empty or both names are equal
-- (partial function).
-- Useful in 'Semigroup' and similar instances.
combineNames
  :: a
  -> a
  -> (a -> UnqualComponentName)
  -> String
  -> UnqualComponentName
combineNames a b tacc tt
  -- One empty or the same.
  | P.null unb
      || una == unb =
      na
  | P.null una = nb
  -- Both non-empty, different.
  | otherwise =
      error $
        "Ambiguous values for "
          ++ tt
          ++ " field: '"
          ++ una
          ++ "' and '"
          ++ unb
          ++ "'"
  where
    (na, nb) = (tacc a, tacc b)
    una = unUnqualComponentName na
    unb = unUnqualComponentName nb
