/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */

#pragma once

#include <string>
#include <vector>

class cmRuntimeDependencyArchive;

class cmBinUtilsWindowsPEGetRuntimeDependenciesTool
{
public:
  cmBinUtilsWindowsPEGetRuntimeDependenciesTool(
    cmRuntimeDependencyArchive* archive);
  virtual ~cmBinUtilsWindowsPEGetRuntimeDependenciesTool() = default;

  virtual bool GetFileInfo(std::string const& file,
                           std::vector<std::string>& needed) = 0;

protected:
  cmRuntimeDependencyArchive* Archive;

  void SetError(std::string const& error);
};
